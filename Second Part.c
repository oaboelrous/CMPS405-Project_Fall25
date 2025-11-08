
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>

#define LOG_FILE "second_part.log"
#define READ_END 0
#define WRITE_END 1
#define BUFFER_SIZE 1024
// all these definitions where defined to make things easier

void taskCreateFile(const char *fileName, char *reportBuf) {
FILE *fp = fopen(fileName, "w"); 
//creating file using fopen from stdio.h
if (fp == NULL) {
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Create}: FAILED to create '%s'", getpid(), fileName);
	return;
} //incase of any errors we still report to the parent
/*
snprintf is just like scanf to put contents into a buffer it's safer and prevents any buffer overflow
*/
	fprintf(fp, "File created by [PID %d]\n", getpid());
/* 
we're outputting into the file fp that this process created this file
*/
	fclose(fp); // closing file from stdio.h
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Create}: SUCCESS. Created '%s'",getpid(), fileName); 
/*
we saved into a buffer pointer then in mainthis will be written by child and then read by parent 
*/
}// end of create task

void taskDeleteFile(const char *fileName, char *reportBuf) {
	if (remove(fileName) == 0)
	//remove returns 0 if file/directory successfully deleted
	{
	/*
	remove function from stdio.h deletes that file/directory
	*/
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Delete}: SUCCESS. Deleted '%s'",getpid(), fileName);
	} 
	else {
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Delete}: FAILED to delete '%s'",getpid(), fileName);
	} // report error occured 

	}// end of delete task

void taskCopyFile(const char *src, const char *dest, char *reportBuf) {
	FILE *fileSrc = fopen(src, "r"); //reading file 
	if (fileSrc == NULL) {
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Copy}: FAILED. Source file '%s' not found.",getpid(), src);
	return;
	} // report error occured 

	FILE *fileDest = fopen(dest, "w");
	if (fileDest == NULL) {
	fclose(fileSrc);
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Copy}: FAILED. Could not open destination '%s'.", getpid(), dest);
	return;
	} // report error occured 

	char c;
	while ((c = fgetc(fileSrc)) != EOF) {
	fputc(c, fileDest);
	//copying into the file character by character
	}
	/* fgetc takes character by character EOF indicated by -1 EOF from stdio.h
	we are building or we can say assigning charcater c letter/character by character
	*/

	fclose(fileSrc);
	fclose(fileDest);
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Copy}: SUCCESS. Copied '%s' to '%s'.", getpid(), src, dest); // saving in buffer for report
	}

void taskDisplayInfo(const char *fileName, char *reportBuf) {
/* 
stat from sys/stat.h its function stat retreives info from a chosen file and saves it in given address 
*/
	struct stat file_stat;
	char timeStr[100];
	int bytesWritten;

	if (stat(fileName, &file_stat) == 0) {
	struct tm *tm_info = localtime(&file_stat.st_mtime);
	strftime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", tm_info);
/* 
retireive time one of the attributes from the stat DS is time but it's in type long then we need to convert it into a readable string using localtime from time.h
*/

	bytesWritten = snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Info}: SUCCESS. File Statistics for '%s':\n - Size: %ld bytes\n",
	getpid(), fileName, (long)file_stat.st_size);

// Append permissions
	bytesWritten += snprintf(reportBuf + bytesWritten, BUFFER_SIZE - bytesWritten, "  - Owner UID: %ld\n - Group GID: %ld\n",(long)file_stat.st_uid, (long)file_stat.st_gid);

// Append time 
	bytesWritten += snprintf(reportBuf + bytesWritten, BUFFER_SIZE - bytesWritten,"  - Last Modified: %s\n",timeStr);

/*struct stat has many fields we retireive st_size, st_uid, and st_gid are fields from the stat structure size, uid (user id), gid (group id)*/

/*
As for the bytesWritten we use it for telling snprintf to start inputing data in reportBuff from index (reportBuf + bytesWritten)
*/

	} else {
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Info}: FAILED. File '%s' not found.",getpid(), fileName);
	}
	}

void taskSearchWord(const char *word, const char *fileName, char *reportBuf) {
	FILE *fp = fopen(fileName, "r"); // reading file
	if (fp == NULL) {
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Search}: FAILED. File '%s' not found.",getpid(), fileName);
	return;
	} // report in case error

	char line[BUFFER_SIZE];
	int found = 0;
	while (fgets(line, sizeof(line), fp) != NULL) 
	// fegets reads line by line and stops if it encounters a EOF or \n (new line) or is stopped by our size limit (sizeof(line) but we are stopping the reading process at when there are no more words NULL is encountered 
	{
	if (strstr(line, word) != NULL) {
	found = 1;
	break;
	}
	}
	fclose(fp); //closing file

	if (found) {
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Search}: SUCCESS. Found '%s' in '%s'.",getpid(), word, fileName);
	} else {
	snprintf(reportBuf, BUFFER_SIZE, "[PID %d] Task {Search}: SUCCESS. Word '%s' NOT found in '%s'.",getpid(), word, fileName);
	}
	}


void taskListDirectory(const char *dir_path, char *reportBuf) {
	char command[BUFFER_SIZE];
	char tempOutputFile[128]; 
	char outputLine[BUFFER_SIZE];
	int bytesWritten;
	FILE *temp_fp;
	int status;

/*whole idea is to write the directories contents in a temporary file and then move it onto the log file 
this temp file needs to be emptied for each new process
*/
/* We first create a temporary file the whole idea is to this is /tmp where unix places it's temporary files when processing*/
	snprintf(tempOutputFile, sizeof(tempOutputFile), "/tmp/ls_output_%d.txt", getpid());

// Build the command: Execute ls -a and redirect output (and error) to the temp file
// Command format: ls -a <dir_path> > /tmp/ls_output_PID.txt 2>&1
	snprintf(command, sizeof(command), "ls -a %s > %s", dir_path, tempOutputFile);
	status = system(command);
/*use system to execute the command but it's redirected to tmp file so it won't show in bash
*/

// Start the report buffer with a header
	bytesWritten = snprintf(reportBuf, BUFFER_SIZE, 
	"[PID %d] Task {List}: SUCCESS. Contents of directory '%s' (via system()):\n--- Directory Content Start ---\n",getpid(), dir_path);

/* status == 0, means system command successed we'll start reading content from the temp file */
	if (status == 0) {
	temp_fp = fopen(tempOutputFile, "r"); // open and read

	if (temp_fp != NULL) {// opened sucessfuly
	// Reading output line by line thanks to fegts
	while (fgets(outputLine, sizeof(outputLine), temp_fp) != NULL) {
	int line_len = strlen(outputLine);

	if (bytesWritten + line_len + 1 < BUFFER_SIZE) 
	// this condition determines if the current line output_line can fit into the remaining space of the `report_buf`.
	{
	strcpy(reportBuf + bytesWritten, outputLine);
	//we are telling it copy outputLine into reportBuf starting from index (reportBuf + bytesWritten
	bytesWritten += line_len; // increment it so that we write next time from a new index
	} else {
	snprintf(reportBuf + bytesWritten, BUFFER_SIZE - bytesWritten, "... [OUTPUT TRUNCATED]\n"); //max size reached
	bytesWritten = BUFFER_SIZE;
	break; 
	}
	}
	fclose(temp_fp);
	}
	} 

//If the command failed report with the failure message
	if (status != 0) {
	snprintf(reportBuf, BUFFER_SIZE, 
	"[PID %d] Task 6 (List): FAILED. Command 'ls -A %s' failed with exit status %d.", getpid(), dir_path, status);
	}

	// 7. Add footer and cleanup
	if (bytesWritten < BUFFER_SIZE) {
	snprintf(reportBuf + bytesWritten, BUFFER_SIZE - bytesWritten, "--- Directory Content End ---"); 
	//if there is still space add this line
	reportBuf[BUFFER_SIZE - 1] = '\0'; //make sure to add the null-terminator
	}

	// Clean up the temporary file
	remove(tempOutputFile); 
	}


void getUtcTimestamp(char *buf, size_t bufsz) {
	time_t t = time(NULL);
	//time(Null) returns  returns current calendar time represented as the number of seconds
	struct tm gm;
	gmtime_r(&t, &gm);
	strftime(buf, bufsz, "%Y-%m-%dT%H:%M:%SZ", &gm); //stringies the time
	}

void printLogFile() {
	FILE *logFile = fopen(LOG_FILE, "r");
	if (logFile == NULL) {
	perror("[Parent] Failed to open log file for final print");
	return;
	}

	char line[BUFFER_SIZE];
	while (fgets(line, sizeof(line), logFile) != NULL) {
	printf("%s", line);
	}// print all contents of log file
	fclose(logFile);
	}


int main(int argc, char *argv[]) {

	if (argc != 7) {
	printf("Usage: %s <file1> <file2> <file3> <word_to_search> <directory_path>  \n",argv[0]);

	//stderr standard error fprintf
	printf("<file1>: Used for create\n");
	printf("<file2>: Used for delete\n");
	printf("<file3>: Used as to copy, info, search from\n");
	printf("<file4>: Used as destination for copy\n");
	printf("<word_to_search>: Used for search\n");
	printf("<directory_path>: Used for directory listing\n");
	exit(EXIT_FAILURE);
	}
// EXIT_FAILURE defined by <stdlib.h> same as exit(1) just something went wrong

	long noProcs = sysconf(_SC_NPROCESSORS_ONLN);
/* 
the line above returns the number of processors the device has
sysconf from <unistd.h> 
_SC_NPROCESSORS_ONLN will give number of avaiable cores
as for type long it's safer when dealing with PROCESSORS in large systems
int would do the job for us
*/

	if (noProcs < 1) noProcs = 2;
	int numSiblings = noProcs/2; 
	if (numSiblings == 0) numSiblings = 1;
// here i just check if the number of siblings to do processing is valid

	printf("Parent process:\nDetected %ld cores. Creating %d sibling processes.\n", noProcs, numSiblings);
// %ld is long integer

	FILE *logFile = fopen(LOG_FILE, "a"); 
//file will be created if doesn't exist
	if (logFile == NULL) {
	perror("Parent process:\nFailed to create log file");
	exit(EXIT_FAILURE);
	} // probably will never happen but just in case

	fprintf(logFile, "--- Parent Log Initialized (PID %d) ---\n", getpid());
	fclose(logFile);
// fprintf means file printf prints to a certain file 

	int pipe_fd[2];
	//pipe function returns a value if -1 returned we hit an error
	if (pipe(pipe_fd) == -1) { 
	perror("Parent pipe ... something went wrong . . .");
	exit(EXIT_FAILURE);
	}

	for (int i = 0; i < numSiblings; i++) {
	pid_t pid = fork();

	if (pid == -1) {
	perror("Parent fork ... something went wrong . . .");
	continue;
	}

	if (pid == 0) { //child process

	close(pipe_fd[READ_END]); //close unused end

	char reportBuffer[BUFFER_SIZE]; 
	// Buffer size is declared in top 
	srand((unsigned int)time(NULL) ^ (unsigned int)getpid());
	int taskId = rand() % 6;
	/*
	srand basically makes rand choose different starting points to implement it's random algorithm making it truly random
	(unsigned int)These are casts. They convert the return types of time()
	*/

	switch (taskId) {
	case 0: taskCreateFile(argv[1], reportBuffer); break;
	case 1: taskDeleteFile(argv[2], reportBuffer); break;
	case 2: taskCopyFile(argv[3], argv[4], reportBuffer); break;
	case 3: taskDisplayInfo(argv[3], reportBuffer); break;
	case 4: taskSearchWord(argv[6], argv[3], reportBuffer); break;
	case 5: taskListDirectory(argv[5], reportBuffer); break;
	}

	write(pipe_fd[WRITE_END], reportBuffer,strlen(reportBuffer) + 1);
/*
reportBuffer is returned from child process so this argument might have just the data like a name "MEQ" so 3 characters ['M','E','Q'], but in C for strings there is a null-terminator '\0' which marks the end of a string in memory.
+ 1 is about making sure the `\0` byte, which already exists in the buffer, is included in the data transfer.
*/

	close(pipe_fd[WRITE_END]); //done using it close it 
	exit(EXIT_SUCCESS);
	}
	}

// back to parent processing
// close unneeded ends
	close(pipe_fd[WRITE_END]);

	logFile = fopen(LOG_FILE, "a"); //LOG_FILE is defined in the beginning
	if (logFile == NULL) {
	perror("Parent Process:\nFailed to open log for appending");
	exit(EXIT_FAILURE);
	}

	printf("Parent Process:\nWaiting for reports from siblings...\n");

	char buffer[BUFFER_SIZE]; //BUFFER_SIZE is defined in the beginning
	char timeStr[100];

// parent reading
/* 
read() function returns a number indicating how much data it successfully read. So as long as it's more than 0 then we read something
also \0 that is at the end of all array's indicating null-terminator so that any reader/stream knows when to stop
*/
	while (read(pipe_fd[READ_END], buffer, sizeof(buffer)) > 0) {
	getUtcTimestamp(timeStr, sizeof(timeStr)); 
	// a function made for time formatting for reporting
	fprintf(logFile, "[%s] %s\n", timeStr, buffer);
	/*
	so in our file for logging we need to put the time and contents of the buffer
	*/
	}

	printf("Parent Process:\nAll reports received. Closing log.\n");
	fclose(logFile);
	close(pipe_fd[READ_END]);

	for (int i = 0; i < numSiblings; i++) {
	wait(NULL);
	}

	printf("\n--- Parent Process All siblings finished. Final Log Contents: ---\n");
	printLogFile();
/* 
this function printLogFile was added so that we don't keep checking the log file after each running of the program
*/

	return 0;
}


