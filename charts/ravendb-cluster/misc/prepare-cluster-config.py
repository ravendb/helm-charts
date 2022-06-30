import argparse
import atexit
import enum
import json
import yaml
import os
import zipfile
from shutil import rmtree
from typing import List, Dict

# CLI Configuration
parser = argparse.ArgumentParser(
    description="Prepares values.yaml file for a RavenDB Helm Chart"
)

parser.add_argument("values_path", type=str, help="Path to existing values.yaml")
parser.add_argument(
    "setup_package_path", type=str, help="Path to RavenDB setup package (.zip)"
)


ARGS = parser.parse_args()
VALUES_YAML_PATH = ARGS.values_path
SETUP_PACKAGE_PATH = ARGS.setup_package_path


class NodeInfo:
    def __init__(self, tag: str, tcp_port: int):
        self.node_tag = tag
        self.public_tcp_port = tcp_port

    def to_yaml(self) -> Dict:
        return {"nodeTag": self.node_tag, "publicTcpPort": self.public_tcp_port}


class SetupMode(enum.Enum):
    NONE = "None"
    LETS_ENCRYPT = "LetsEncrypt"

    def __str__(self):
        return self.value


class ClusterInfo:
    def __init__(
        self,
        node_infos: List[NodeInfo] = None,
        license_str: str = None,
        setup_mode: SetupMode = None,
        letsencrypt_email: str = None,
    ):
        self.node_infos = node_infos
        self.license = json.loads(license_str)
        self.setup_mode = setup_mode
        self.letsencrypt_email = letsencrypt_email

    def to_yaml(self) -> Dict:
        return {
            "license": json.dumps(self.license),
            "setupMode": str(self.setup_mode),
            "letsEncryptEmail": self.letsencrypt_email
            if self.letsencrypt_email
            else "",
            "nodes": [node_info.to_yaml() for node_info in self.node_infos],
        }


def get_cluster_info_from_setup_package(setup_package_zip_path: str) -> ClusterInfo:
    zip_file = zipfile.ZipFile(setup_package_zip_path, "r")
    os.mkdir("./package")

    letsencrypt_email = None
    node_infos = []
    
    print(f"Extracting files from {SETUP_PACKAGE_PATH}...")

    zip_file.extractall("./package")
    zip_file.close()

    atexit.register(rmtree, "./package")

    print("Reading license string..")

    with open("./package/license.json") as license_file_ref:
        ravendb_license_string = license_file_ref.read()

    last_settings_json = None
    
    print("Reading nodes settings..")

    # Gather settings json hooks
    for file_name in os.listdir("./package"):
        if os.path.isdir(f"./package/{file_name}"):
            with open(f"./package/{file_name}/settings.json") as settings_json_ref:
                settings = json.loads(settings_json_ref.read())
                port = settings["PublicServerUrl.Tcp"].split(":")[-1]
                node_tag = settings["PublicServerUrl.Tcp"].split("//")[1][0]
                node_infos.append(NodeInfo(node_tag, port))
                last_settings_json = settings

    print("Checking SetupMode..")

    setup_mode = SetupMode(last_settings_json["Setup.Mode"])
    if setup_mode == SetupMode.LETS_ENCRYPT:
        print("SetupMode is LetsEncrypt, reading LetsEncrypt email..")
        letsencrypt_email = last_settings_json["Security.Certificate.LetsEncrypt.Email"]

    return ClusterInfo(
        node_infos, ravendb_license_string, setup_mode, letsencrypt_email
    )


def update_values_yaml(cluster_info: ClusterInfo, values_yaml_path: str) -> None:
    try:
        with open(values_yaml_path, "r+") as values_file:
            values_yaml = yaml.safe_load(values_file)
    except Exception as e:
        raise IOError("Failed to load values.yaml file", e)

    values_yaml.update(cluster_info.to_yaml())

    with open(values_yaml_path, "w") as values_file:
        yaml.dump(values_yaml, values_file)


cluster_info = get_cluster_info_from_setup_package(SETUP_PACKAGE_PATH)

print("Extracted cluster info from setup package successfully.")
print(f"Updating '{VALUES_YAML_PATH}' file...")

update_values_yaml(cluster_info, VALUES_YAML_PATH)
print(f"Updated '{VALUES_YAML_PATH}' file successfully! Happy Helming :)")