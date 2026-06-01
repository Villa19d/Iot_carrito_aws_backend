import json
import os

class StatusModel:
    def __init__(self, file_path):
        self.file_path = file_path
        self._init_file()

    def _init_file(self):
        if not os.path.exists(self.file_path):
            with open(self.file_path, "w") as f:
                json.dump({"status": False}, f)

    def get_status(self):
        with open(self.file_path, "r") as f:
            return json.load(f)

    def set_status(self, value: bool):
        data = {"status": value}
        with open(self.file_path, "w") as f:
            json.dump(data, f)
        return data