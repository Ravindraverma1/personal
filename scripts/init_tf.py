import sys
import os
import ast
sys.path.append("../config")
sys.path.append("var")
from config_values import *
import boto3
from jinja2 import Environment
import json
import requests
import math
#if tf_variables['enable_aurora'] == "true":
#    from var import tf_vars_aurora as TF
#else:
#    from var import tf_vars as TF

PATH_TO_THIS_SCRIPT = os.path.dirname(os.path.abspath(__file__))
PATH_TO_INFRA_REPO  = os.path.join(PATH_TO_THIS_SCRIPT, "../")

PATH_TO_CONFIG = os.path.join(PATH_TO_THIS_SCRIPT, "../config")
CONFIG_FILE = os.path.join(PATH_TO_CONFIG, "config_values.py")

# PATH_TO_INFRA_TEMP  = os.path.join(PATH_TO_THIS_SCRIPT, "../temp")
# TMP_FILE = os.path.join(PATH_TO_INFRA_TEMP, "export.params")

TFVARS_FILE = os.path.join(PATH_TO_INFRA_REPO, "terraform.tfvars")
PATH_TO_MODULE_TF_FILE = os.path.join(PATH_TO_THIS_SCRIPT, "../modules/db/")
MOD_TF_PARAM_FILE_POSTFIX = "-param-group.tf"
MOD_TF_OPTION_FILE_POSTFIX = "-option-group.tf"
MOD_TF_MAIN_FILE_POSTFIX = "-main.tf"
PATH_TO_TEMPLATE_DIR = os.path.join(PATH_TO_THIS_SCRIPT, "../modules/db/engine-templates")
PATH_TO_UPGRADE_DIR = os.path.join(PATH_TO_THIS_SCRIPT, "../modules/db/upgrade")
PATH_TO_DB_RESYNC_DIR = os.path.join(PATH_TO_THIS_SCRIPT, "../modules/db/resync")
BILLION_MULTIPLIER = 1000000000

SOURCE_CIDR_BLOCKS_ALLOWED = """
variable "source_cidr_blocks_allowed" {
    type = list
    default = [
{%- for block in source_cidr_blocks_allowed %}
        "{{ block.block }}", # {{ block.comment }}
{%- endfor %}
    ]
}
"""

SOURCE_VPCES_ALLOWED = """
variable "source_vpces_allowed" {
    type = list
    default = [
{%- for vpce in source_vpces_allowed %}
        "{{ vpce.vpce }}", # {{ vpce.comment }}
{%- endfor %}
    ]
}
"""

VPN_CONNECTIONS = """
variable "vpn_connections" {
    type = "list"
    default = [
    {%- for vpn in vpn_connections %}
       {
           customer_bgp_asn = "{{ vpn.customer_bgp_asn }}",
           customer_internal_cidr_block = "{{ vpn.customer_internal_cidr_block }}",
           customer_vpn_gtw_ip = "{{ vpn.customer_vpn_gtw_ip }}",
           vpn_static_routes = "{{ vpn.vpn_static_routes }}",
           enable_vpn_acceleration = "{{ vpn.enable_vpn_acceleration }}"
        },
    {%- endfor %}
    ]
}

variable "customer_internal_cidr_list" {
    type = "list"
    default = [
    {%- for vpn in vpn_connections %}
      {%- for cidr_block in vpn.customer_internal_cidr_block %}
        "{{ cidr_block }}",
      {%- endfor %}
    {%- endfor %}
    ]
}
"""

USER_WORKSPACES = """
variable user_workspaces {
    type = any
    default =[
    {%- for user in user_workspaces %}
       {
        "user_name" = "{{ user.user_name }}"
       },
    {%- endfor %}
    ]
}
"""

TF_VARS = """
tfstate_bucket_name  = "{{tfstate_bucket_name}}"
sst_account_id       = "{{sst_account_id}}"
release              = "{{release}}"
aws_region           = "{{aws_region}}"
elk_region           = "{{elk_region}}"
env                  = "{{env}}"
jenkins_env          = "{{jenkins_env}}"
spot_price           = "{{spot_price}}"
customer             = "{{customer}}"
dd_id                = "{{dd_id}}"
dd_app               = "{{dd_app}}"
env_aws_profile      = "{{env_aws_profile}}"
env_account_id       = "{{env_account_id}}"
vpnowner_aws_profile = "{{vpnowner_aws_profile}}"
vpnowner_account_id  = "{{vpnowner_account_id}}"
enable_dd            = "{{enable_dd}}"
cv_version           = "{{cv_version}}"
internal_cidr_start1 = "{{internal_cidr_start1}}"
internal_cidr_start2 = "{{internal_cidr_start2}}"
{%- for prop, value in ec2_instance_types.items() %}
instance_type_{{ prop }} = "{{value}}"
{%- endfor %}
{%- for prop, value in ebs_vol_size.items() %}
{{ prop }} = "{{value}}"
{%- endfor %}
db_instance_class              = "{{db_instance_class}}"
db_engine_version              = "{{db_engine_version}}"
db_engine                      = "{{db_engine}}"
db_id                          = "{{db_id}}"
db_snapshot_id                 = "{{db_snapshot_id}}"
db_allocated_storage           = "{{db_allocated_storage}}"
db_max_allocated_storage       = "{{db_max_allocated_storage}}"
db_apply_immediately           = "{{db_apply_immediately}}"
db_multi_az                    = "{{db_multi_az}}"
db_parameter_group_family      = "{{db_parameter_group_family}}"
db_backup_retention_period     = "{{db_backup_retention_period}}"
db_maintenance_window          = "{{db_maintenance_window}}"
db_backup_window               = "{{db_backup_window}}"
db_snapshot_schedule           = "{{db_snapshot_schedule}}"
db_copy_tags_to_snapshot       = "{{db_copy_tags_to_snapshot}}"
db_enable_snapshot_cleanup     = "{{db_enable_snapshot_cleanup}}"
db_snapshot_retention_years    = "{{db_snapshot_retention_years}}"
db_snapshot_retention_months   = "{{db_snapshot_retention_months}}"
db_snapshot_retention_weeks    = "{{db_snapshot_retention_weeks}}"
db_snapshot_retention_weekdays = "{{db_snapshot_retention_weekdays}}"
db_snapshot_cleanup_schedule   = "{{db_snapshot_cleanup_schedule}}"
{%- for param, param_val in rds_parameters.items() %}
{{ param }} = "{{ param_val }}"
{%- endfor %}
elk_vpc              = "{{elk_vpc}}"
use_2az              = "{{use_2az}}"
enable_vpn_access    = "{{enable_vpn_access}}"
aws_asn_side         = "{{aws_asn_side}}"
vpn_ecmp_support     = "{{vpn_ecmp_support}}"
use_transit_gateway  = "{{use_transit_gateway}}"
#cv_s3_policy_ip_list = {{cv_s3_policy_ip_list}}
disable_os_command   = "{{disable_os_command}}"
disable_oracle_ssl   = "{{disable_oracle_ssl}}"
customer_domain      = "{{customer_domain}}"
axcloud_domain       = "{{axcloud_domain}}"
infra_domains        = {{infra_domains}}
saas_env             = "{{saas_env}}"
saas_customer        = "{{saas_customer}}"
service_type         = "{{service_type}}"
enable_migration_peering = "{{enable_migration_peering}}"
r_package_mapper    = "{{r_package_mapper}}"
r_package_install_list = "{{r_package_install_list}}"
customer_timezone         = "{{customer_timezone}}"
customer_adfs_identifier = "{{customer_adfs_identifier}}"
customer_ldap_ip       = "{{customer_ldap_ip}}"
customer_directory_name = "{{customer_directory_name}}"
switch_saml           = "{{switch_saml}}"
logz_enable           = "{{logz_enable}}"
cv_log_level   = "{{cv_log_level}}"
enable_outbound_transfer = "{{enable_outbound_transfer}}"
blacklisted_cv_tag = "{{blacklisted_cv_tag}}"
{%- for action, settings in efs.items() %}
{{ action }} = "{{ settings }}"
{%- endfor %}
enable_redshift      = "{{enable_redshift}}"
{%- for key, value in redshift.items() %}
{{ key }} = "{{ value }}"
{%- endfor %}
enable_service_monitoring = "{{enable_service_monitoring}}"
{%- for key, value in service_monitoring.items() %}
{{ key }} = "{{ value }}"
{%- endfor %}
enable_citrixservices = "{{enable_citrixservices}}"
enable_worm_compliance = "{{enable_worm_compliance}}"
{%- for src, schema in dbsources.items() %}
{{ src }} = "{{ schema }}"
{%- endfor %}
{%- for key, value in data_lineage_config.items() %}
{{ key }} = "{{ value }}"
{%- endfor %}
enable_aurora = "{{enable_aurora}}"
aurora_db_engine= "{{aurora_db_engine}}"
aurora_db_engine_version= "{{aurora_db_engine_version}}"
aurora_db_instance_class= "{{aurora_db_instance_class}}"
enable_occ_file_share = "{{enable_occ_file_share}}"
occ_env_tag = "{{occ_env_tag}}"
aws_managed_directory = "{{aws_managed_directory}}"
enable_workspaces = "{{enable_workspaces}}"
internal_sec_cidr_start1 = "{{internal_sec_cidr_start1}}"
internal_sec_cidr_start2 = "{{internal_sec_cidr_start2}}"
workspace_bundle_id   = "{{workspace_bundle_id}}"
use_datascope_refinitiv = "{{use_datascope_refinitiv}}"
higher_environments = [
{%- for e in higher_environments %}
{ environment_name = "{{e.environment_name}}",
  environment_account_id = "{{e.environment_account_id}}" },
{%- endfor %} ]
lower_environments = [
{%- for e in lower_environments %}
{ environment_name = "{{e.environment_name}}",
  environment_account_id = "{{e.environment_account_id}}" },
{%- endfor %} ]
enable_rest = "{{enable_rest}}"
{%- for key, value in archive_audit.items() %}
{{ key }} = "{{ value }}"
{%- endfor %}
{%- for key, value in ebs_housekeeping.items() %}
{{ key }} = "{{ value }}"
{%- endfor %}
enable_oci_db = "{{enable_oci_db}}"
vcn_cidr = "{{vcn_cidr}}"
first_oci_dbsource_user = "{{first_oci_dbsource_user}}"
oci_mtu_size = "{{oci_mtu_size}}"
enable_snowflake = "{{snowflake.get('enable_snowflake')}}"
sf_vpc_endpoint = "{{snowflake.get('sf_vpc_endpoint')}}"
sf_whitelist_privatelink = [
{%- for e in snowflake.get('sf_whitelist_privatelink') %}
{ host = "{{e.get('host')}}",
  type = "{{e.get('type')}}",
  port = "{{e.get('port')}}"},
{%- endfor %} ]
sf_dbsources = [
{%- for e in snowflake.get('sf_dbsources') %}
{ dbsource_name = "{{e.get('dbsource_name')}}",
  sf_db = "{{e.get('sf_db')}}",
  sf_schema = "{{e.get('sf_schema')}}"},
{%- endfor %} ]
{%- for key, value in override_whitelist_config.items() %}
{{ key }} = "{{ value }}"
{%- endfor %}
{%- for key, value in spark.items() %}
{%- if key in ['exe_bootstrap_action', 'thrift_bootstrap_action', 'exe_applications', 'thrift_applications'] %}
{{ key }} = {{ value }}
{%- elif key in ['exe_configurations_json', 'thrift_configurations_json', 'exe_task_group_configs'] %}
{{ key }} = <<EOF
{{ value|tojson }}
EOF
{%- else %}
{{ key }} = "{{ value }}"
{%- endif %}
{%- endfor %}
{%- for key, value in logzio.items() %}
{{ key }} = "{{value}}"
{%- endfor %}
{%- for key, value in citrixservices_owner.items() %}
{%- if key in ['citrixservices_route_table_ids'] %}
{{ key }} = {{ value }}
{%- else %}
{{ key }} = "{{ value }}"
{%- endif %}
{%- endfor %}
{%- for key, value in webproxy.items() %}
{{ key }} = "{{ value }}"
{%- endfor %}
enable_sftp_transfer = "{{enable_sftp_transfer}}"
mft_app_region = "{{mft_app_region}}"
web_proxy_nat_eips_mft_region = "{{web_proxy_nat_eips_mft_region}}"
{%- for key, value in mvt.items() %}
{{ key }} = "{{ value }}"
{%- endfor %}
enable_byok = "{{ enable_byok }}"
enable_pgp = "{{ enable_pgp }}"
enable_env_health_check = "{{ enable_env_health_check }}"
{%- for key, value in map_tagging_config.items() %}
{{ key }} = "{{ value }}"
{%- endfor %}
"""

tf_variables['tfstate_bucket_name'] = "axiom-test-tf-" + tf_variables['customer'] + \
    "-" + tf_variables['env'] + "-" + tf_variables['aws_region']



def IF(condition, val1, val2):
    if isinstance(val1, set):
        val1 = list(val1)[0]
    return val1 if condition else val2


def GREATEST(arg1, arg2):
    if isinstance(arg1, set):
        arg1 = list(arg1)[0]
    return arg1 if arg1 > arg2 else arg2


def LEAST(arg1, arg2):
    if isinstance(arg1, set):
        arg1 = list(arg1)[0]
    return arg1 if arg1 < arg2 else arg2


def SUM(*args):
    return sum(args)


def write_template(content, file_name):
    with open(file_name, "w") as this_file:
        this_file.write(content)
        this_file.flush()


def append_template(content , path_to_file):
    with open(path_to_file, "a") as fl:
        fl.write(content+"\n")


def render_template(this_template, kwargs):
    return Environment().from_string(this_template).render(**kwargs)


def get_ec2_instance_spec(ec2_instance_type):
    with open('%s/ec2_instances.json' % PATH_TO_CONFIG) as inputFile:
        jData = json.load(inputFile)
    ec2_spec = list([itr for itr in jData['instance_class'] if itr['class_name'] == ec2_instance_type.strip()])[0]
    return ec2_spec


# calculates allocated max heap memory to half of its EC2 instance memory
#return heap memory in MB to support 10.0.18 xmx parameter
def calc_heap_memory(ec2_instance_type):
    ec2_spec = get_ec2_instance_spec(ec2_instance_type)
    instance_mem = ec2_spec['memory']
    heap_mem = str(int(math.ceil(float(instance_mem) / 2)*1024))
    return heap_mem


def update_rds_params(rds_instance_type, iStr, db_instances_json_path='../config'):
    try:
        if iStr["enable_aurora"] == "true":
            return iStr
    except KeyError:
        pass

    DBInstanceClassMemory=""  # this variable must be called so with all cases in-tact!
    DBInstanceClassNCPU="" # to calc max_parallel_workers and max_worker_processes (new in 10.6)
    with open('%s/db_instances.json' % db_instances_json_path) as inputFile:
        jData = json.load(inputFile)
    for itr in jData['instance_class']:
        if itr['class_name'] == rds_instance_type.strip():
            DBInstanceClassMemory = float(itr['memory'])
            DBInstanceClassNCPU = int(itr['ncpu'])

    # input was in GiB, convert into bytes
    DBInstanceClassMemory *= BILLION_MULTIPLIER
    print("Updating RDS parameters using DBInstanceClassMemory=%s" % DBInstanceClassMemory)
    print("Updating RDS parameters using DBInstanceClassNCPU=%s" % DBInstanceClassNCPU)

    for row in list(iStr["rds_parameters"].items()):
        param_name = str(row[0])
        param_value = row[1]
        print("Updating %s\nOld value=%s" % (param_name, param_value))
        iStr['rds_parameters'].update({param_name: str(eval("int(%s)" % param_value))})
        print("New value=%s" % iStr['rds_parameters'][param_name])
    return iStr


def process_rds_params(rds_instance_type, module_tf_var_file, db_instances_json_path='../config'):
    rds_params_list = {}
    if tf_variables["enable_aurora"] == "true":
        print("RDS params not processed")
    else:
        with open('%s/db_instances.json' % db_instances_json_path) as inputFile:
            jData = json.load(inputFile)
        # search_result = filter(lambda itr: itr['class_name'] == rds_instance_type.strip(), jData)[0]
        search_result = list([itr for itr in jData['instance_class'] if itr['class_name'] == rds_instance_type.strip()])[0]
        if len(search_result) == 0:
            print("{0} is not found in db_instances.json".format(rds_instance_type))
        else:
            print("{0} found in db_instances.json".format(rds_instance_type))
        print(search_result['memory'])

        # DBInstanceClassMemory is used in the eval function dynamically below, input was in GiB, convert into bytes
        DBInstanceClassMemory = float(search_result['memory']) * BILLION_MULTIPLIER

        # search_result for DBInstance core value
        search_result_ncpu = list([itr for itr in jData['instance_class'] if itr['class_name'] == rds_instance_type.strip()])[0]
        if len(search_result_ncpu) == 0:
            print("{0} is not found in db_instances.json".format(rds_instance_type))
        else:
            print("{0} found in db_instances.json".format(rds_instance_type))
        print(search_result_ncpu['ncpu'])

        # DBInstanceClassNCPU is used in the eval function dynamically below
        DBInstanceClassNCPU = int(search_result_ncpu['ncpu'])

        for row in list(tf_variables["rds_parameters"].items()):
            rds_params_list[row[0]] = str(eval("int(" + row[1] + ")"))  # evaluate formula
        print(rds_params_list)

        # use these rds_param_values to update the module tf file
        ignore_parm_list = ['synchronous_commit']
        for curr_row in rds_params_list:
            if curr_row in ignore_parm_list:
                if rds_params_list['synchronous_commit'] == '1':
                    sed_command = 'sed -i \'s/\(.*\<synchronous_commit\>.*\)default.*=.*".*"\(.*\)/\\1default="off"\\2/g\' {0}'
                    os.system(sed_command.format(module_tf_var_file))
                else:
                    sed_command = 'sed -i \'s/\(.*\<synchronous_commit\>.*\)default.*=.*".*"\(.*\)/\\1default="off"\\2/g\' {0}'
                    os.system(sed_command.format(module_tf_var_file))
            else:
                sed_command = 'sed -i \'s/\(.*\<{0}\>.*\)default.*=.*".*"\(.*\)/\\1default="{1}"\\2/g\' {2}'
                replace_cmd = sed_command.format(curr_row, rds_params_list[curr_row], module_tf_var_file)
                os.system(replace_cmd)


def get_db_param_group_family(aws_profile):
    v_engine = ""
    v_engine_version = ""
    deprecated_versions={"9.6.3" : "postgres9.6", "10.6" : "postgres10"  , "11.8" : "postgres11" , "12.4" : "postgres12"} #map deprecated versions to group.
    try:

        if tf_variables['enable_aurora'] == "true":
            v_engine = tf_variables['aurora_db_engine']
            v_engine_version = tf_variables['aurora_db_engine_version']

        if tf_variables['enable_aurora'] == "false":
            v_engine = tf_variables['db_engine']
            v_engine_version = tf_variables['db_engine_version']
        else:
            v_engine = "postgres"
            v_engine_version = "9.6.3"

    except KeyError:
        v_engine = "postgres"
        v_engine_version = "9.6.3"

    boto3.setup_default_session(profile_name=aws_profile)
    rds = boto3.client("rds")
    print("describe_db_engine_versions=%s" % v_engine_version)
    res = rds.describe_db_engine_versions(
           Engine=v_engine,
           EngineVersion=v_engine_version
          )
    print("res=%s" % res)
    if res['DBEngineVersions']:
        return res['DBEngineVersions'][0]['DBParameterGroupFamily']
    else:
        return deprecated_versions[v_engine_version]


##now used for both param and option groups
def activate_rds_param_tf_config(tf_file_name):
    # curr_filename = tf_file_name+".old"
    command_str = "cp "+tf_file_name+" "+PATH_TO_MODULE_TF_FILE+"default-param-group.tf"
    os.popen(''+command_str)

def activate_rds_tf_config(tf_file_name,config_name,db_param_family, resync_path, module_path):
    command_str = ""
    if config_name == "main":
        if db_param_family == "postgres12":
            # for postgres12, also copy over the postgres9.6*.tf files
            print("cp "+resync_path+"/postgres9.6* "+module_path)
            os.popen(''+"cp "+resync_path+"/postgres9.6* "+module_path)
            #finally set the required main file to be copied
            command_str = "cp "+tf_file_name+" "+module_path+config_name+".tf"
        if db_param_family == "postgres11":
            # for postgres11, also copy over the postgres9.6*.tf files
            print("cp "+resync_path+"/postgres9.6* "+module_path)
            os.popen(''+"cp "+resync_path+"/postgres9.6* "+module_path)
            #finally set the required main file to be copied
            command_str = "cp "+tf_file_name+" "+module_path+config_name+".tf"
        if db_param_family == "postgres10":
            # for postgres10, also copy over the postgres9.6*.tf files
            print("cp "+resync_path+"/postgres9.6* "+module_path)
            os.popen(''+"cp "+resync_path+"/postgres9.6* "+module_path)
            #finally set the required main file to be copied
            command_str = "cp "+tf_file_name+" "+module_path+config_name+".tf"
        if db_param_family == "postgres9.6":
            # set the required main file to be copied
            command_str = "cp " + tf_file_name + " " + module_path + config_name + ".tf"
        if db_param_family == "oracle-se2-12.1" or db_param_family == "oracle-ee-12.1":
            command_str = "cp " + tf_file_name + " " + module_path + config_name + ".tf"
        if db_param_family == "oracle-se2-19" or db_param_family == "oracle-ee-19":
            # finally set the required main file to be copied
            command_str = "cp " + tf_file_name + " " + module_path + config_name + ".tf"
    else:
        command_str = "cp "+tf_file_name+" "+module_path+"default-"+config_name+"-group.tf"
    print("RunCommand - "+command_str)
    os.popen(''+command_str)


def activate_rds_upgrade_tf_config():
    if tf_variables['db_engine'] == "postgres":
        tf_param_filename = "postgres10" + MOD_TF_PARAM_FILE_POSTFIX
        tf_option_filename = "postgres10" + MOD_TF_OPTION_FILE_POSTFIX
        tf_main_filename = "postgres10-main.tf"
        #tf_variables['db_parameter_group_family'] = "postgres10"
    else:
        tf_param_filename = "oracle-se2-19" + MOD_TF_PARAM_FILE_POSTFIX
        tf_option_filename = "oracle-se2-19" + MOD_TF_OPTION_FILE_POSTFIX
        tf_main_filename = "oracle-se2-19-main.tf"
        #tf_variables['db_parameter_group_family'] = "oracle-se2-19"
    tf_param_file = os.path.join(PATH_TO_UPGRADE_DIR, tf_param_filename)
    tf_option_file = os.path.join(PATH_TO_UPGRADE_DIR, tf_option_filename)
    tf_main_file =  os.path.join(PATH_TO_UPGRADE_DIR, tf_main_filename)

    print("Upgrade file1:{0}".format(tf_param_file))
    print("Upgrade file2:{0}".format(tf_option_file))
    print("Upgrade file3:{0}".format(tf_main_file))

    os.popen(''+"cp "+tf_param_file+" "+PATH_TO_MODULE_TF_FILE+"default-param-group-upg.tf")
    os.popen(''+"cp "+tf_option_file+" "+PATH_TO_MODULE_TF_FILE+"default-option-group-upg.tf")
    os.popen(''+"cp "+tf_main_file+" "+PATH_TO_MODULE_TF_FILE+"main.tf")


def replace_all(text, dic):
    for i, j in list(dic.items()):
        text = text.replace(i, j)
    return text


def return_list(input_str):
    res_lst = []
    subtitution = {"u": "", "\'": "\"", "[": "[ ", "]": " ]"}
    for res_str in input_str.split(","):
        res_lst.append(res_str)
    print(replace_all(str(res_lst), subtitution))
    return replace_all(str(res_lst), subtitution)


def init_cv_s3_policy_ip_list(customer_vpn_gtw_ip):
    s = ""
    quote = "\""
    customer_vpn_gtw_ip = customer_vpn_gtw_ip.replace("[", "").replace("]", "").replace("\"", "").split(",")
    for i in range(len(customer_vpn_gtw_ip)):
        print(i)
        s += quote + customer_vpn_gtw_ip[i].strip() + quote
        if i < len(customer_vpn_gtw_ip) - 1:
            s += ","
    print("{0}={1}".format("cv_s3_policy_ip_list", s))
    return s

def get_boto_session():
    """
    Gets boto session
    :return: target_session
    """
    temp_aws_profile = os.environ['ENV_AWS_PROFILE']
    target_session = boto3.Session(profile_name=temp_aws_profile)
    return target_session

def is_dl_enabled(tf_variables,in_param):

    is_lineage_enabled = os.getenv("ENABLE_DATA_LINEAGE", tf_variables['data_lineage_config']['enable_data_lineage'])
    #variable to verify if dl is true via the config map
    dl_map_enabled = "false"
    if tf_variables['data_lineage_config']['enable_data_lineage'] == "true" and is_lineage_enabled != "true":
        print("Data Lineage is already enabled. Cannot set it back to %s." % is_lineage_enabled)
        exit(1)

    cv_major_version = ".".join(tf_variables['cv_version'].split("_")[0:3])

    target_session = get_boto_session()
    client = target_session.client('s3')
    # Access the datalineage_cv_map.json file from S3 bucket
    data = client.get_object(Bucket='axiom-data-transfer', Key='datalineage/common/datalineage_cv_map.json')
    file_content = data["Body"].read().decode()
    mapping = json.loads(file_content)
    found = False
    for map_item in mapping['dl_cv_map']:
        if map_item['cv_major_version'] == cv_major_version:
            found = True
            if map_item['dl_enabled'] == "true":
                dl_map_enabled = "true"
            else:
                print("DL is not enabled/supported for this CV version")
                dl_map_enabled = "false"
    if not found:
        print("DL mapping for this CV version does not exist")
        dl_map_enabled = "false"

    if in_param == "None":
        return items['data_lineage_config']['enable_data_lineage']
    else:
        if dl_map_enabled == "true":
            return in_param
        if dl_map_enabled == "false":
            return "false"


if __name__ == "__main__":
    aws_profile = sys.argv[1]
    try:
        upgrade_rds = sys.argv[2]
    except IndexError:
        upgrade_rds = "false"

    tf_variables['env_aws_profile'] = aws_profile

    tf_variables['disable_os_command'] = "false" if ('disable_os_command' in tf_variables and tf_variables['disable_os_command'] == "false") else "true"

    if ('saas_env' not in tf_variables) or ('saas_customer' not in tf_variables) or ('service_type' not in tf_variables):
        tf_variables.update(service_type = "saas")
        tf_variables.update(saas_env = "empty")
        tf_variables.update(saas_customer = "empty")

    if tf_variables['saas_env'] == "":
        tf_variables['saas_env'] = "empty"

    if tf_variables['saas_customer'] == "":
        tf_variables['saas_customer'] = "empty"

    if tf_variables['service_type'] == "":
        tf_variables['service_type'] = "saas"

    if "cv_log_level" not in tf_variables or tf_variables['cv_log_level'] == "":
        tf_variables['cv_log_level'] = "INFO"

    if "aws_asn_side" not in tf_variables:
        tf_variables['aws_asn_side'] = "64512"
    elif tf_variables['aws_asn_side'] == "":
        tf_variables['aws_asn_side'] = "64512"

    if "vpn_ecmp_support" not in tf_variables:
        tf_variables['vpn_ecmp_support'] = "enable"
    elif tf_variables['vpn_ecmp_support'] == "":
        tf_variables['vpn_ecmp_support'] = "enable"

    if "enable_migration_peering" not in tf_variables:
        tf_variables['enable_migration_peering'] = "false"

    if "use_transit_gateway" not in tf_variables:
        tf_variables['use_transit_gateway'] = "false"

    if "vpnowner_account_id" not in tf_variables or tf_variables['vpnowner_account_id'] == "":
        tf_variables['vpnowner_account_id'] = tf_variables['env_account_id']
        tf_variables['vpnowner_aws_profile'] = tf_variables['env_aws_profile']

    # allocate max heap size of ec2 instances
    if "cv_xmx" not in tf_variables['ec2_instance_types']:
        tf_variables['ec2_instance_types']['cv_xmx'] = calc_heap_memory(tf_variables['ec2_instance_types']['cv'])

    if "tomcat_xmx" not in tf_variables['ec2_instance_types']:
        tf_variables['ec2_instance_types']['tomcat_xmx'] = calc_heap_memory(tf_variables['ec2_instance_types']['tomcat'])

    if "enable_aurora" not in tf_variables:
        tf_variables["enable_aurora"] = "false"

    # get the db-param group family namespace via aws cli, sets the tf_variable - db_parameter_group_family
    print("PATH_TO_INFRA_REPO="+PATH_TO_INFRA_REPO)
    tf_variables['db_parameter_group_family'] = get_db_param_group_family(aws_profile)

    if "disable_oracle_ssl" not in tf_variables:
        tf_variables['disable_oracle_ssl'] = "false"

    if "use_2az" not in tf_variables:
        tf_variables['use_2az'] = "0"

    if "enable_outbound_transfer" not in tf_variables:
        tf_variables['enable_outbound_transfer'] = "false"

    if "blacklisted_cv_tag" not in tf_variables:
        tf_variables['blacklisted_cv_tag'] = "runStatement"

    if "db_max_allocated_storage" not in tf_variables:
        tf_variables['db_max_allocated_storage'] = "0"

    #Initialize new ebs vars for old environmnet resyncing
    if "ebs_vol_size" not in tf_variables:
        tf_variables['ebs_vol_size']={}
        try:
            tf_variables['ebs_vol_size']['cv_vol_size'] = os.environ['TF_VAR_cv_vol_size']
            tf_variables['ebs_vol_size']['tomcat_vol_size'] = os.environ['TF_VAR_tomcat_vol_size']
            tf_variables['ebs_vol_size']['cv_log_vol_size'] = os.environ['TF_VAR_cv_log_vol_size']
            tf_variables['ebs_vol_size']['tomcat_log_vol_size'] = os.environ['TF_VAR_tomcat_log_vol_size']
        except KeyError: #our terraform default
            tf_variables['ebs_vol_size']['cv_vol_size'] = "10"
            tf_variables['ebs_vol_size']['tomcat_vol_size'] = "10"
            tf_variables['ebs_vol_size']['cv_log_vol_size'] = "10"
            tf_variables['ebs_vol_size']['tomcat_log_vol_size'] = "10"

    #Initialize environment without separate axiom and log volumes - between iac 1.18 and iac 1.22
    if "ebs_vol_size" in tf_variables and "cv_log_vol_size" not in tf_variables['ebs_vol_size'] and "tomcat_log_vol_size" not in tf_variables['ebs_vol_size']:
            tf_variables['ebs_vol_size']['cv_log_vol_size'] = tf_variables['ebs_vol_size']['cv_vol_size']
            tf_variables['ebs_vol_size']['tomcat_log_vol_size'] = tf_variables['ebs_vol_size']['tomcat_vol_size']

    #Initialize new efs vars for old environment resyncing
    if 'efs' not in tf_variables:
        tf_variables['efs'] = {'efs_throughput_mode': 'bursting', 'efs_provisioned_throughput': '0'}

    if "enable_redshift" not in tf_variables:
        tf_variables['enable_redshift'] = "false"

    if "redshift" not in tf_variables:
        tf_variables['redshift'] = {'cluster_node_type': '', 'cluster_number_of_nodes': ''}

    if "wlm_json_config" not in tf_variables['redshift']:
        tf_variables['redshift']['wlm_json_config'] = "[{\\\"query_concurrency\\\": 5}]"

    if "enable_service_monitoring" not in tf_variables:
        tf_variables['enable_service_monitoring'] = "false"

    if "service_monitoring" not in tf_variables:
        tf_variables['service_monitoring'] = { 'monitor_workflow_execution': 'false', 'monitor_workflow_execution_cron': 'cron(0 0/1 ? * * *)' }

    if "monitoring_api" not in tf_variables['service_monitoring']:
        if tf_variables['enable_service_monitoring'] == "true":  # Keep using datadog if service monitoring is already enabled
            tf_variables['service_monitoring']['monitoring_api'] = "datadog"
        else:
            tf_variables['service_monitoring']['monitoring_api'] = "logzio"

    if "s3_archive_filefolder" in tf_variables:
        del tf_variables['s3_archive_filefolder']

    if "enable_citrixservices" not in tf_variables:
        tf_variables['enable_citrixservices'] = "false"

    if "archive_audit" not in tf_variables:
        tf_variables['archive_audit'] = {'enable_archive_audit': '', 'archive_audit_cron': '',  'archive_audit_project_name': '', 'archive_audit_branch_name': '', 'archive_audit_wf_name': '', 'archive_audit_var_projectname': '', 'archive_audit_var_branchname': ''}


    try:
        tf_variables['enable_worm_compliance'] = os.environ['ENABLE_WORM_COMPLIANCE']
    except KeyError:
        pass

    if "enable_worm_compliance" not in tf_variables:
        tf_variables['enable_worm_compliance'] = "false"

    if "use_datascope_refinitiv" not in tf_variables:
        tf_variables['use_datascope_refinitiv'] = "false"

    if "enable_rest" not in tf_variables:
        tf_variables['enable_rest'] = "false"

    if "ebs_housekeeping" not in tf_variables:
        if tf_variables['jenkins_env'] == "development":
            tf_variables['ebs_housekeeping'] = {'ebs_backup_schedule': "cron(0 12 * * ? 2099)",
                                                'ebs_snapshot_cleanup_schedule': "cron(0 12 * * ? 2099)",
                                                'min_days_retention': "7"}
        elif tf_variables['jenkins_env'] == "staging":
            tf_variables['ebs_housekeeping'] = {'ebs_backup_schedule': "cron(0 0/6 ? * * *)",
                                                'ebs_snapshot_cleanup_schedule': "cron(5 0 */2 * ? *)",
                                                'min_days_retention': "7"}
        else:
            tf_variables['ebs_housekeeping'] = {'ebs_backup_schedule': "cron(0 0/2 ? * * *)",
                                                'ebs_snapshot_cleanup_schedule': "cron(5 0 */2 * ? *)",
                                                'min_days_retention': "7"}

    #init DL variable as per mapping
    try:
        tf_variables['data_lineage_config']['enable_data_lineage'] = is_dl_enabled(tf_variables, os.environ['ENABLE_DATA_LINEAGE'])
    except KeyError:
        pass

    if "enable_data_lineage" in tf_variables:
        tf_variables['data_lineage_config'] = { 'enable_data_lineage': tf_variables['enable_data_lineage'], 'dl_version': "", 'license_type': ""}
        del tf_variables['enable_data_lineage']

    if "aws_managed_directory" not in tf_variables:
        tf_variables['aws_managed_directory'] = "false"

    if "enable_workspaces" not in tf_variables:
        tf_variables['enable_workspaces'] = "false"

    if "higher_environments" not in tf_variables:
        tf_variables['higher_environments'] = []

    if "lower_environments" not in tf_variables:
        tf_variables['lower_environments'] = []

    #if aurora-postgres is selected - default db-engine to postgres + 10.6 for back-compatibility with dynamo variables
    if tf_variables['db_engine'] == "Select":
        tf_variables['db_engine'] = "postgres"
        tf_variables['db_engine_version'] = tf_variables['aurora_db_engine_version']

    #tf_variables['ses_ip_range'] = ses_ip_range()

    # creating a list of all email domains:
    try:
        if tf_variables['axcloud_domain'] == "":
            tf_variables['axcloud_domain'] = os.environ['AXCLOUD_DOMAIN']
    except KeyError:
        pass
    email_prefix = "*@"
    infra_domains_list = []
    infra_domains_list = [email_prefix + x for x in tf_variables["customer_domain"].replace(" ","").split(",")]

    try:
     if tf_variables["axcloud_domain"] != "":
         infra_domains_list.append(email_prefix + tf_variables["axcloud_domain"])

    except KeyError:
        pass
    tf_variables["infra_domains"] = json.dumps(infra_domains_list)

    # Initialize new schema name
    # This is the default that gets added via deploy-cv-service
    # Updated further via add-dbsource pipeline
    if "dbsource_names" in tf_variables:
        if len(tf_variables['dbsource_names'].split(",")) > 1 :  #if dbsources were added in the old method, convert them to map
            tf_variables['dbsources'] = dict(list(zip(tf_variables['dbsource_names'].split(","), tf_variables['cv_schema_names'].split(","))))
        del tf_variables['dbsource_names']
        del tf_variables['cv_schema_names']

    if "dbsources" not in tf_variables:
        print("dbsources not found in dynamo-get")
        print(tf_variables['db_engine'])

        if tf_variables['db_engine'] == "postgres":
               tf_variables['dbsources'] = {"CV10USR": "udata"}
        else:
            if "oracle" in tf_variables['db_engine']:
                    tf_variables['dbsources'] = {"CV10USR": "axiom_user"}
    else:
        print("dbsource map found in dynamo-get")

    if "enable_pgp_encryption" in tf_variables:
        del tf_variables['enable_pgp_encryption']

    if "enable_env_health_check" not in tf_variables:
        if tf_variables['jenkins_env'] != "development":
            tf_variables['enable_env_health_check'] = "true"
        else:
            tf_variables['enable_env_health_check'] = "false"

    if "enable_pgp" not in tf_variables:
        tf_variables['enable_pgp'] = "false"

    if "vcn_cidr" not in tf_variables:
        tf_variables['vcn_cidr'] = " "

    if "first_oci_dbsource_user" not in tf_variables:
        tf_variables['first_oci_dbsource_user'] = " "

    #initialise oci-db-enabled to false
    if "enable_oci_db" not in tf_variables:
        tf_variables['enable_oci_db'] = "false"

    if tf_variables['enable_oci_db'] == "true":
        tf_variables['oci_mtu_size'] = "1500"

    if "snowflake" not in tf_variables:
        tf_variables['snowflake'] = { 'enable_snowflake': "false",
                                      'sf_vpc_endpoint': "",
                                      'sf_whitelist_privatelink': [],
                                      'sf_dbsources': []}

    #  Prepare Logz.io variables to be env specific but default to Global Parameter values if not yet present
    if "logzio" not in tf_variables:
        tf_variables['logzio'] = {'logzio_listener_host': os.environ['TF_VAR_logzio_listener_host'],
                                  'logzio_proxy_host': os.environ['TF_VAR_logzio_proxy_host'],
                                  'logs_logzio_token': os.environ['TF_VAR_logs_logzio_token'],
                                  'metrics_logzio_token': os.environ['TF_VAR_metrics_logzio_token'],
                                  'enable_app_metrics_monitoring': "false"}

    if "spark" not in tf_variables:
        tf_variables['spark'] = {
            'enable_spark': "false",
            'keep_spark_data': "false"
        }

    if "override_whitelist" in tf_variables:
        tf_variables['override_whitelist_config'] = { 'override_classes': tf_variables['override_whitelist'], 'override_services': tf_variables['override_whitelist'], 'whitelist_classes': tf_variables['whitelist_classes'], 'whitelist_services': tf_variables['whitelist_services']}
        del tf_variables['override_whitelist']
        del tf_variables['whitelist_classes']
        del tf_variables['whitelist_services']

    if "citrixservices_owner" not in tf_variables:
        tf_variables['citrixservices_owner'] = {}

    if "webproxy" not in tf_variables:
        tf_variables['webproxy'] = {
            'enable_webproxy': "false"
        }

    if "enable_sftp_transfer" not in tf_variables:
        tf_variables['enable_sftp_transfer'] = "false"

    if "mvt" not in tf_variables:
        tf_variables['mvt'] = {
            'enable_mvt_access': "false"
        }

    if "enable_byok" not in tf_variables:
        tf_variables['enable_byok'] = "false"

    if "source_vpces_allowed" not in tf_variables:
        tf_variables['source_vpces_allowed'] = []

    if 'map_tagging_config' not in tf_variables:
        tf_variables['map_tagging_config'] = {'map_tag_key': 'map-migrated-na', 'map_tag_value': 'not applicable resource'}

    # Initialize db-source name
    # This is the default that gets added via deploy-cv-service
    # Updated further via add-dbsource pipeline

    MOD_TF_PARAM_FILENAME = tf_variables['db_parameter_group_family'].strip() + MOD_TF_PARAM_FILE_POSTFIX
    MOD_TF_OPTION_FILENAME = tf_variables['db_parameter_group_family'].strip() + MOD_TF_OPTION_FILE_POSTFIX
    MOD_TF_MAIN_FILENAME = tf_variables['db_parameter_group_family'].strip() + MOD_TF_MAIN_FILE_POSTFIX

    MOD_TF_PARAM_FILE = os.path.join(PATH_TO_TEMPLATE_DIR, MOD_TF_PARAM_FILENAME)
    MOD_TF_OPTION_FILE = os.path.join(PATH_TO_TEMPLATE_DIR, MOD_TF_OPTION_FILENAME)
    MOD_TF_MAIN_FILE = os.path.join(PATH_TO_TEMPLATE_DIR, MOD_TF_MAIN_FILENAME)
    try:
        if tf_variables['enable_aurora'] == "false":
            db_instance_class = tf_variables['db_instance_class']
            process_rds_params(db_instance_class.strip(), MOD_TF_PARAM_FILE)
        else:
            db_instance_class = tf_variables['aurora_db_instance_class']
    except KeyError:
        tf_variables['enable_aurora'] = "false"
        try:
            #was due to a variable name change
            db_instance_class = tf_variables['rds_instance_type']
        except KeyError:
            #this should be present in all recent scenarios
            db_instance_class = tf_variables['db_instance_class']
        process_rds_params(db_instance_class.strip(), MOD_TF_PARAM_FILE)


    # activate specific TF file to prevent TF resource conflict
    #activate_rds_param_tf_config(MOD_TF_PARAM_FILE)
    #if not upgrade_rds.strip() == "true":
    print("Updating rds config files")
    print("File1:{0}".format(MOD_TF_PARAM_FILE))
    print("File2:{0}".format(MOD_TF_OPTION_FILE))
    print("File3:{0}".format(MOD_TF_MAIN_FILE))
    activate_rds_tf_config(MOD_TF_PARAM_FILE, "param", tf_variables['db_parameter_group_family'],
                           PATH_TO_DB_RESYNC_DIR, PATH_TO_MODULE_TF_FILE)
    activate_rds_tf_config(MOD_TF_OPTION_FILE, "option", tf_variables['db_parameter_group_family'],
                           PATH_TO_DB_RESYNC_DIR, PATH_TO_MODULE_TF_FILE)
    activate_rds_tf_config(MOD_TF_MAIN_FILE, "main", tf_variables['db_parameter_group_family'],
                           PATH_TO_DB_RESYNC_DIR, PATH_TO_MODULE_TF_FILE)

    if upgrade_rds.strip() == "true":
        print("Copying rds upgrade config files")
        activate_rds_upgrade_tf_config()

    variables = update_rds_params(db_instance_class.strip(), tf_variables)

    write_template("tf_variables = " + json.dumps(variables, indent=4), CONFIG_FILE)
    print("Updated config_values.py with RDS param values")
    variables2 = render_template(TF_VARS, variables)
    print(variables2)
    write_template(variables2, TFVARS_FILE)

    cidr_blocks = render_template(SOURCE_CIDR_BLOCKS_ALLOWED, tf_variables)
    print(cidr_blocks)
    write_template(cidr_blocks, PATH_TO_INFRA_REPO+"/"+"allowed-cidr-blocks.tf")

    vpces = render_template(SOURCE_VPCES_ALLOWED, tf_variables)
    print(vpces)
    write_template(vpces, PATH_TO_INFRA_REPO+"/"+"allowed-vpces.tf")
    with open(PATH_TO_INFRA_REPO+"/"+"allowed-vpces.tf", 'r') as f:
        print("allowed-vpces.tf:")
        print(f.read())
    #if tf_variables['enable_vpn_access'] != "false":
    vpn_connections = render_template(VPN_CONNECTIONS, tf_variables)
    print(vpn_connections)
    # grant access to this tf variable at account vpn and env level
    write_template(vpn_connections, PATH_TO_INFRA_REPO + "/" + "variables-vpn-connections.tf")
    write_template(vpn_connections, PATH_TO_INFRA_REPO + "/tf-vpn/" + "variables-vpn-connections.tf")

    #render workspace user vars
    user_workspaces = render_template(USER_WORKSPACES, tf_variables)
    print(user_workspaces)
    write_template(user_workspaces, PATH_TO_INFRA_REPO + "/" + "variables-workspace-users.tf")