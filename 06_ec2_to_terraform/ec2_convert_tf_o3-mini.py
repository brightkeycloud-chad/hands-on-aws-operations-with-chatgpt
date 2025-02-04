#!/usr/bin/env python3
import sys
import boto3
import datetime

def get_instance_details(region, instance_id):
    """
    Retrieve the instance details using boto3.
    """
    ec2 = boto3.client("ec2", region_name=region)
    response = ec2.describe_instances(InstanceIds=[instance_id])
    reservations = response.get("Reservations", [])
    if not reservations:
        raise Exception("No reservations found for instance {}".format(instance_id))
    instances = reservations[0].get("Instances", [])
    if not instances:
        raise Exception("Instance {} not found".format(instance_id))
    return instances[0]

def tf_bool(value):
    return str(value).lower()

def write_attribute(lines, attr, value, indent=2):
    """Helper to write a simple key = "value" attribute line if value is not None."""
    if value is not None:
        if isinstance(value, bool):
            value_str = tf_bool(value)
        else:
            value_str = value
        lines.append(" " * indent + '{} = "{}"'.format(attr, value_str))

def generate_terraform(instance):
    """
    Generate a Terraform template (HCL) string from the instance details.
    This template attempts to assign every set parameter:
      - Parameters that map directly to Terraform attributes are set.
      - Other parameters are output as comments.
    """
    # Use a sanitized resource name; Terraform resource names must match naming rules.
    resource_name = instance["InstanceId"].replace("-", "_")

    tf_lines = []
    tf_lines.append('# Generated Terraform template for EC2 instance details')
    tf_lines.append('# The following values are from describe_instances.  Some are configurable and some are computed.')
    tf_lines.append('resource "aws_instance" "{}" {{'.format(resource_name))

    # --- Directly configurable attributes ---
    # Required: AMI and instance_type
    if instance.get("ImageId"):
        tf_lines.append('  ami           = "{}"'.format(instance["ImageId"]))
    if instance.get("InstanceType"):
        tf_lines.append('  instance_type = "{}"'.format(instance["InstanceType"]))

    if instance.get("KeyName"):
        tf_lines.append('  key_name      = "{}"'.format(instance["KeyName"]))

    if instance.get("SubnetId"):
        tf_lines.append('  subnet_id     = "{}"'.format(instance["SubnetId"]))

    # If PrivateIpAddress is set and the instance is launched in a subnet, we can specify it.
    if instance.get("PrivateIpAddress"):
        tf_lines.append('  private_ip    = "{}"'.format(instance["PrivateIpAddress"]))

    # ENA support is configurable in terraform (since v2.0 provider)
    if "EnaSupport" in instance:
        tf_lines.append('  ena_support   = {}'.format(tf_bool(instance["EnaSupport"])))

    # SourceDestCheck is configurable
    if "SourceDestCheck" in instance:
        tf_lines.append('  source_dest_check = {}'.format(tf_bool(instance["SourceDestCheck"])))

    # Monitoring configuration: Terraform uses "monitoring" (true/false)
    if "Monitoring" in instance and "State" in instance["Monitoring"]:
        # Note: AWS returns a dict like {"State": "disabled"} or {"State": "enabled"}
        monitoring_enabled = instance["Monitoring"]["State"].lower() == "enabled"
        tf_lines.append('  monitoring = {}'.format(tf_bool(monitoring_enabled)))

    # Availability zone is set via Placement block (if available)
    placement = instance.get("Placement", {})
    if placement.get("AvailabilityZone"):
        tf_lines.append('  availability_zone = "{}"'.format(placement["AvailabilityZone"]))
    if placement.get("Tenancy"):
        tf_lines.append('  tenancy = "{}"'.format(placement["Tenancy"]))

    # Security Groups: Prefer VPC security group IDs if available.
    security_groups = instance.get("SecurityGroups", [])
    sg_ids = [sg.get("GroupId") for sg in security_groups if sg.get("GroupId")]
    if sg_ids:
        tf_lines.append('  vpc_security_group_ids = [')
        for sg in sg_ids:
            tf_lines.append('    "{}",'.format(sg))
        tf_lines.append('  ]')

    # Credit Specification block (if present)
    if instance.get("CreditSpecification"):
        credit = instance["CreditSpecification"]
        if credit.get("CpuCredits"):
            tf_lines.append("")
            tf_lines.append("  credit_specification {")
            tf_lines.append('    cpu_credits = "{}"'.format(credit["CpuCredits"]))
            tf_lines.append("  }")

    # CPU Options block (if present)
    if instance.get("CpuOptions"):
        cpu = instance["CpuOptions"]
        tf_lines.append("")
        tf_lines.append("  cpu_options {")
        if "CoreCount" in cpu:
            tf_lines.append('    core_count       = {}'.format(cpu["CoreCount"]))
        if "ThreadsPerCore" in cpu:
            tf_lines.append('    threads_per_core = {}'.format(cpu["ThreadsPerCore"]))
        tf_lines.append("  }")

    # Capacity Reservation Specification block (if present)
    if instance.get("CapacityReservationSpecification"):
        cap_spec = instance["CapacityReservationSpecification"]
        tf_lines.append("")
        tf_lines.append("  capacity_reservation_specification {")
        if cap_spec.get("CapacityReservationPreference"):
            tf_lines.append('    capacity_reservation_preference = "{}"'.format(
                cap_spec["CapacityReservationPreference"]))
        if cap_spec.get("CapacityReservationTarget"):
            target = cap_spec["CapacityReservationTarget"]
            if target.get("CapacityReservationId"):
                tf_lines.append("    capacity_reservation_target {")
                tf_lines.append('      capacity_reservation_id = "{}"'.format(
                    target["CapacityReservationId"]))
                tf_lines.append("    }")
        tf_lines.append("  }")

    # Hibernation Options (Terraform aws_instance supports setting hibernation)
    if instance.get("HibernationOptions") and "Configured" in instance["HibernationOptions"]:
        # If configured is True, we set hibernation = true
        tf_lines.append('  hibernation = {}'.format(tf_bool(instance["HibernationOptions"]["Configured"])))

    # Metadata Options block (if present)
    if instance.get("MetadataOptions"):
        meta = instance["MetadataOptions"]
        tf_lines.append("")
        tf_lines.append("  metadata_options {")
        for key, value in meta.items():
            if isinstance(value, bool):
                tf_lines.append("    {} = {}".format(key, tf_bool(value)))
            elif isinstance(value, int):
                tf_lines.append("    {} = {}".format(key, value))
            else:
                tf_lines.append('    {} = "{}"'.format(key, value))
        tf_lines.append("  }")

    # --- Block Device Mappings ---
    bdmappings = instance.get("BlockDeviceMappings", [])
    if bdmappings:
        tf_lines.append("")
        tf_lines.append("  # Block device mappings")
    for mapping in bdmappings:
        device_name = mapping.get("DeviceName")
        if "Ebs" in mapping and mapping["Ebs"]:
            ebs = mapping["Ebs"]
            tf_lines.append("  ebs_block_device {")
            tf_lines.append('    device_name = "{}"'.format(device_name))
            if "VolumeId" in ebs:
                # VolumeId is read-only in TF; include as a comment.
                tf_lines.append('    # volume_id = "{}"'.format(ebs["VolumeId"]))
            if "DeleteOnTermination" in ebs:
                tf_lines.append('    delete_on_termination = {}'.format(tf_bool(ebs["DeleteOnTermination"])))
            if "Status" in ebs:
                tf_lines.append('    # status = "{}"'.format(ebs["Status"]))
            if "AttachTime" in ebs:
                attach_time = ebs["AttachTime"]
                if isinstance(attach_time, (str,)):
                    at_str = attach_time
                else:
                    at_str = attach_time.strftime("%Y-%m-%dT%H:%M:%SZ")
                tf_lines.append('    # attach_time = "{}"'.format(at_str))
            tf_lines.append("  }")
        else:
            # For ephemeral (instance store) volumes, Terraform uses ephemeral_block_device
            tf_lines.append("  ephemeral_block_device {")
            tf_lines.append('    device_name = "{}"'.format(device_name))
            if mapping.get("VirtualName"):
                tf_lines.append('    virtual_name = "{}"'.format(mapping["VirtualName"]))
            tf_lines.append("  }")

    # --- Tags ---
    tags = instance.get("Tags", [])
    if tags:
        tf_lines.append("")
        tf_lines.append("  tags = {")
        for tag in tags:
            key = tag.get("Key")
            value = tag.get("Value", "")
            tf_lines.append('    "{}" = "{}"'.format(key, value))
        tf_lines.append("  }")

    # --- Other parameters that are returned but not directly configurable in aws_instance ---
    tf_lines.append("")
    tf_lines.append("  # The following are instance attributes returned by AWS that cannot be set via Terraform.")
    computed_fields = [
        ("InstanceId", instance.get("InstanceId")),
        ("AmiLaunchIndex", instance.get("AmiLaunchIndex")),
        ("State", instance.get("State", {}).get("Name")),
        ("PrivateDnsName", instance.get("PrivateDnsName")),
        ("PublicDnsName", instance.get("PublicDnsName")),
        ("StateTransitionReason", instance.get("StateTransitionReason")),
        ("LaunchTime", instance.get("LaunchTime")),
        ("Architecture", instance.get("Architecture")),
        ("RootDeviceType", instance.get("RootDeviceType")),
        ("RootDeviceName", instance.get("RootDeviceName")),
        ("VirtualizationType", instance.get("VirtualizationType")),
        ("ClientToken", instance.get("ClientToken")),
        ("Platform", instance.get("Platform")),
        ("Hypervisor", instance.get("Hypervisor")),
        ("IamInstanceProfile", instance.get("IamInstanceProfile")),
        ("InstanceLifecycle", instance.get("InstanceLifecycle")),
        ("SpotInstanceRequestId", instance.get("SpotInstanceRequestId")),
        ("EnclaveOptions", instance.get("EnclaveOptions")),
        ("BootMode", instance.get("BootMode")),
        ("PlatformDetails", instance.get("PlatformDetails")),
    ]
    for field, value in computed_fields:
        if value is not None:
            # Format dates
            if isinstance(value, (datetime.datetime)):
                value = value.strftime("%Y-%m-%dT%H:%M:%SZ")
            tf_lines.append("  # {}: {}".format(field, value))

    tf_lines.append("}")
    return "\n".join(tf_lines)

def main():
    if len(sys.argv) != 3:
        print("Usage: {} <region> <instance-id>".format(sys.argv[0]))
        sys.exit(1)

    region = sys.argv[1]
    instance_id = sys.argv[2]

    try:
        instance = get_instance_details(region, instance_id)
    except Exception as e:
        print("Error retrieving instance details: {}".format(e))
        sys.exit(1)

    terraform_template = generate_terraform(instance)

    output_file = "instance.tf"
    with open(output_file, "w") as f:
        f.write(terraform_template)
    print("Terraform template generated in '{}'".format(output_file))

if __name__ == "__main__":
    main()

