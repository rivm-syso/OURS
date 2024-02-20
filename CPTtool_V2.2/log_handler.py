"""
Log handler
"""
# import packages
import os

class LogFile:
    def __init__(self, output_folder, index):
        # checks if file_path exits. If not creates file_path
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)

        self.file = open(os.path.join(output_folder, "log_file_" + str(index) + ".txt"), "w")
        return

    def error_message(self, message):
        r"""
        Error message for the log file

        Parameters
        ----------
        :param message: message that will be displayed
        """

        self.file.write("# Error # : " + message + "\n")
        return

    def warning_message(self, message):
        r"""
        Warning message for the log file

        Parameters
        ----------
        :param message: message that will be displayed
        """

        self.file.write("# Warning # : " + message + "\n")
        return

    def info_message(self, message):
        r"""
        Warning message for the log file

        Parameters
        ----------
        :param message: message that will be displayed
        """

        self.file.write("# Info # : " + message + "\n")
        return

    def close(self):
        self.file.close()
        return
