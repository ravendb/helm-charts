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

parser.add_argument(
    "input",
    type=str,
    help="Path to RavenDB setup package (.zip)",
)
parser.add_argument(
    "output",
    type=str,
    help="Path to values.yaml file "
    "(it may be a new file or existing one - instead of creating new one or overwriting it'll be updated).",
)
parser.add_argument(
    "chart",
    type=str,
    help="Path to Helm Chart - providing such will help to prepare packageFileGlobPath.",
)

ARGS = parser.parse_args()
VALUES_YAML_PATH = ARGS.output
SETUP_PACKAGE_PATH = ARGS.input
CHART_PATH = ARGS.chart


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


class ClusterChartConfig:
    def __init__(
        self,
        node_infos: List[NodeInfo] = None,
        license_str: str = None,
        setup_mode: SetupMode = None,
        letsencrypt_email: str = None,
        domain_name: str = None,
    ):
        self.domain_name = domain_name
        self.node_infos = node_infos
        self.license = json.loads(license_str)
        self.setup_mode = setup_mode
        self.letsencrypt_email = letsencrypt_email
        self.package_file_glob_path = os.path.relpath(
            os.path.join(os.path.dirname(__file__), SETUP_PACKAGE_PATH), CHART_PATH
        )
        self.image_pull_policy = "IfNotPresent"
        self.storage_size = "5Gi"

    def to_yaml(self) -> Dict:
        return {
            "license": json.dumps(self.license),
            "setupMode": str(self.setup_mode),
            "letsEncryptEmail": self.letsencrypt_email
            if self.letsencrypt_email
            else "",
            "nodes": [node_info.to_yaml() for node_info in self.node_infos],
            "packageFileGlobPath": self.package_file_glob_path,
            "domain": self.domain_name,
            "storageSize": self.storage_size,
        }


def get_cluster_info_from_setup_package(
    setup_package_zip_path: str,
) -> ClusterChartConfig:
    try:
        with zipfile.ZipFile(setup_package_zip_path, "r") as zip_file:
            os.mkdir("./package")
            letsencrypt_email = None
            node_infos = []
            print(f"Extracting files from {SETUP_PACKAGE_PATH}...")
            zip_file.extractall("./package")
    except Exception as e:
        raise IOError(
            "Cannot open the setup package file. File not found or is corrupted.", e
        )

    atexit.register(rmtree, "./package")

    print("Reading license string..")

    with open("./package/license.json") as license_file_ref:
        ravendb_license_string = license_file_ref.read()

    last_settings_json = None

    print("Reading nodes settings..")

    # Gather settings json hooks
    for file_name in os.listdir("./package"):
        if not os.path.isdir(f"./package/{file_name}"):
            break
        with open(f"./package/{file_name}/settings.json") as settings_json_ref:
            settings = json.loads(settings_json_ref.read())
            port = settings["PublicServerUrl.Tcp"].split(":")[-1]
            node_tag = settings["PublicServerUrl.Tcp"].split("//")[1][0]
            node_infos.append(NodeInfo(node_tag, port))
            last_settings_json = settings

    print("Checking SetupMode and domain name..")

    setup_mode = SetupMode(last_settings_json["Setup.Mode"])
    domain_name = ".".join(
        last_settings_json["PublicServerUrl"]
        .split("://")[1]
        .split(":")[0]
        .split(".")[1:]
    )

    if setup_mode == SetupMode.LETS_ENCRYPT:
        print("SetupMode is LetsEncrypt, reading LetsEncrypt email..")
        letsencrypt_email = last_settings_json["Security.Certificate.LetsEncrypt.Email"]

    return ClusterChartConfig(
        node_infos, ravendb_license_string, setup_mode, letsencrypt_email, domain_name
    )


def update_values_yaml(cluster_info: ClusterChartConfig, values_yaml_path: str) -> None:
    values_yaml = {}
    if os.path.exists(VALUES_YAML_PATH):
        try:
            with open(values_yaml_path, "r") as values_file:
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
