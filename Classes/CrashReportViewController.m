//
//  CrashReportViewController.m
//  WordPress
//
//  Created by Chris Boyd on 10/22/10.
//  Code is poetry.
//

#import "CrashReportViewController.h"

@implementation CrashReportViewController
@synthesize crashData;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.title = @"Crash Detected";
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
	[[PLCrashReporter sharedReporter] purgePendingCrashReport];
	[super viewWillDisappear:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(DeviceIsPad() == YES)
		return YES;
	else
		return NO;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
	[self finish];
}

- (IBAction)yes:(id)sender {
	PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
	NSError *error;
	crashData = [[crashReporter loadPendingCrashReportDataAndReturnError: &error] retain];
	if(crashData != nil) {
		PLCrashReport *report = [[[PLCrashReport alloc] initWithData:crashData error: &error] autorelease];
		if (report == nil) {
			NSLog(@"Could not parse crash report");
		}
		else if([MFMailComposeViewController canSendMail]) {
			// Create a mail message with the crash report
			NSMutableString *body = [NSMutableString stringWithString:@"Please see the attached crash report."];
			MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
			NSString *subject = [NSString stringWithFormat:@"WordPress %@ Crash Report", 
								 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
			[controller setMailComposeDelegate:self];
			[controller setToRecipients:[NSArray arrayWithObject:@"crashreport@automattic.com"]];
			[controller setSubject:subject];
			
			// Add specific exception info if available
			if(report.hasExceptionInfo) {
				[body appendFormat:@"Exception %@ -- %@\n", report.exceptionInfo.exceptionName, report.exceptionInfo.exceptionReason];
			}
			
			// Set the message body and add the log as an attachment
			[controller setMessageBody:body isHTML:NO];
			[controller addAttachmentData:crashData mimeType:@"application/octet-stream" fileName:@"crash.log"];
			
			// Present and release
			[self presentModalViewController:controller animated:YES];
			[controller release];
		}
	}
}

- (IBAction)no:(id)sender {
	[self finish];
}

- (IBAction)disable:(id)sender {
	[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"crash_report_dontbug"];
	[self finish];
}

- (void)finish {
	if(DeviceIsPad())
		[super.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
	[crashData release], crashData = nil;
    [super dealloc];
}


@end
