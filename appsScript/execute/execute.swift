 // @license
 // Copyright Google LLC
 //
 // Licensed under the Apache License, Version 2.0 (the "License");
 // you may not use this file except in compliance with the License.
 // You may obtain a copy of the License at
 //
 //     https://www.apache.org/licenses/LICENSE-2.0
 //
 // Unless required by applicable law or agreed to in writing, software
 // distributed under the License is distributed on an "AS IS" BASIS,
 // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 // See the License for the specific language governing permissions and
 // limitations under the License.
 
// [START apps_script_api_execute]
// Calls an Apps Script function to list the folders in the user's
// root Drive folder.
func callAppsScript() {
    output.text = "Getting folders..."

    // Create an execution request object.
    let request = GTLRScript_ExecutionRequest()
    request.function = "getFoldersUnderRoot"

    // Make the API request.
    let query = GTLRScriptQuery_ScriptsRun.query(withObject: request, scriptId: kScriptId)
    service.executeQuery(query,
                         delegate: self,
                         didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:)))
}

// Displays the retrieved folders returned by the Apps Script function.
func displayResultWithTicket(ticket: GTLRServiceTicket,
                             finishedWithObject operation : GTLRScript_Operation,
                             error : NSError?) {
    if let error = error {
        // The API encountered a problem before the script
        // started executing.
        showAlert(title: "The API returned the error: ",
                  message: error.localizedDescription)
        return
    }

    if let apiError = operation.error {
        // The API executed, but the script returned an error.

        // Extract the first (and only) set of error details and cast as
        // a Dictionary. The values of this Dictionary are the script's
        // 'errorMessage' and 'errorType', and an array of stack trace
        // elements (which also need to be cast as Dictionaries).
        let err = apiError.details![0]
        var errMessage = String(
            format:"Script error message: %@\n",
            err.jsonValue(forKey: "errorMessage") as! String)

        if let stacktrace =
            err.jsonValue(forKey: "scriptStackTraceElements") as? [[String: AnyObject]] {
            // There may not be a stacktrace if the script didn't start
            // executing.
            for trace in stacktrace {
                let f = trace["function"] as? String ?? "Unknown"
                let num = trace["lineNumber"] as? Int ?? -1
                errMessage += "\t\(f): \(num)\n"
            }
        }

        // Set the output as the compiled error message.
        output.text = errMessage
    } else {
        // The result provided by the API needs to be cast into the
        // correct type, based upon what types the Apps Script function
        // returns. Here, the function returns an Apps Script Object with
        // String keys and values, so must be cast into a Dictionary
        // (folderSet).
        let folderSet = operation.response?.jsonValue(forKey: "result") as! [String: AnyObject]
        if folderSet.count == 0 {
            output.text = "No folders returned!\n"
        } else {
            var folderString = "Folders under your root folder:\n"
            for (id, folder) in folderSet {
                folderString += "\t\(folder) (\(id))\n"
            }
            output.text = folderString
        }
    }
}
// [END apps_script_api_execute]
