// Copyright Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// [START apps_script_api_execute]
// Calls an Apps Script function to list the folders in the user's
// root Drive folder.
- (void)callAppsScript {
    // Create an execution request object.
    GTLRScript_ExecutionRequest *request = [GTLRScript_ExecutionRequest new];
    request.function = @"getFoldersUnderRoot";

    // Make the API request.
    GTLRScriptQuery_ScriptsRun *query =
    [GTLRScriptQuery_ScriptsRun queryWithObject:request
                                       scriptId:kScriptID];
    [self.service executeQuery:query
                      delegate:self
             didFinishSelector:@selector(displayResultWithTicket:finishedWithObject:error:)];
}

// Displays the retrieved folders returned by the Apps Script function.
- (void)displayResultWithTicket:(GTLRServiceTicket *)ticket
                     finishedWithObject:(GTLRScript_Operation *) response
                                  error:(NSError *)error {
    if (error == nil) {
        NSMutableString *output = [[NSMutableString alloc] init];
        if (response.error != nil) {
            // The API executed, but the script returned an error.

            // Extract the first (and only) set of error details and cast as a
            // NSDictionary. The values of this dictionary are the script's
            // 'errorMessage' and 'errorType', and an array of stack trace
            // elements (which also need to be cast as NSDictionaries).
            GTLRScript_Status_Details_Item *err = response.error.details[0];
            [output appendFormat:@"Script error message: %@\n",
             [err JSONValueForKey:@"errorMessage"]];

            if ([err JSONValueForKey:@"scriptStackTraceElements"]) {
                // There may not be a stacktrace if the script didn't start
                // executing.
                [output appendString:@"Script error stacktrace:\n"];
                for (NSDictionary *trace in [err JSONValueForKey:@"scriptStackTraceElements"]) {
                    [output appendFormat:@"\t%@: %@\n",
                     [trace objectForKey:@"function"],
                     [trace objectForKey:@"lineNumber"]];
                }
            }

        } else {
            // The result provided by the API needs to be cast into the correct
            // type, based upon what types the Apps Script function returns.
            // Here, the function returns an Apps Script Object with String keys
            // and values, so must be cast into a NSDictionary (folderSet).
            NSDictionary *folderSet = [response.response JSONValueForKey:@"result"];
            if (folderSet == nil) {
                [output appendString:@"No folders returned!\n"];
            } else {
                [output appendString:@"Folders under your root folder:\n"];
                for (id folderId in folderSet) {
                    [output appendFormat:@"\t%@ (%@)\n",
                     [folderSet objectForKey:folderId],
                     folderId];
                }
            }
        }
        self.output.text = output;
    } else {
        // The API encountered a problem before the script started executing.
        NSMutableString *message = [[NSMutableString alloc] init];
        [message appendFormat:@"The API returned an error: %@\n",
         error.localizedDescription];
        [self showAlert:@"Error" message:message];
    }
}
// [END apps_script_api_execute]
