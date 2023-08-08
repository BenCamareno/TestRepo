import boto3
import time
import datetime
import os
import logging

logger = logging.getLogger()
# Set logging level to INFO for troubleshoot
logger.setLevel(logging.INFO)
# logger.setLevel(logging.WARNING)

def get_session(role_arn):
    logger.info('Assuming the role: ' + str(role_arn))
    sts = boto3.client('sts')
    resp = sts.assume_role(
        RoleArn=role_arn,
        RoleSessionName='PatchManagerSession'
    )
    credentials = resp['Credentials']
    session = boto3.session.Session(
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken']
    )
    return session

def find_target_tag():
    # Change the maintenance window target based on the time of the day
    os.environ['TZ'] = 'Australia/Sydney'
    time.tzset()
    day = time.strftime('%A', time.localtime())
    hour = time.strftime('%H', time.localtime())
    tag_value = '{}-{}:00AEST'.format(day,hour)
    print("find_target_tag function retuned {}".format(tag_value))
    return tag_value

def first_week_of_month():
    # Returns true if the current day is within the first week of the month
    os.environ['TZ'] = 'Australia/Sydney'
    time.tzset()
    date = time.strftime('%d', time.localtime())
    if int(date) <= 7:
        return True
    else:
        return False
    
def get_week_number_of_month(date):
    # Get the first day of the month
    first_day_of_month = date.replace(day=1)

    # Calculate the number of days between the first day of the month and the input date
    days_passed = (date - first_day_of_month).days

    # Calculate the week number by dividing the days passed by 7 and adding 1
    week_number = (days_passed // 7) + 1

    return week_number

def update_patch_baselines(session,windows_delay_days, rhel_delay_days):
    client = session.client('ssm')
    patch_baselines = []
    patch_baselines.append({'patch_baseline_id': client.get_default_patch_baseline(OperatingSystem='WINDOWS')['BaselineId'], 'operating_system':'windows'})
    patch_baselines.append({'patch_baseline_id': client.get_default_patch_baseline(OperatingSystem='REDHAT_ENTERPRISE_LINUX')['BaselineId'], 'operating_system':"rhel"})

    for patch_baseline in patch_baselines:        
        print("Found the default patch baseline {}".format(patch_baseline))
        # Set the right delay window
        if patch_baseline['operating_system'] == 'windows':
            approve_after_days = windows_delay_days
        elif patch_baseline['operating_system'] == 'rhel':
            approve_after_days = rhel_delay_days
        
        # Exclude AWS managed patch baselines
        if not 'arn:aws:ssm' in patch_baseline['patch_baseline_id']:
            # To update ApprovalRules in a PatchBaseline, PatchFilterGroup must be sent in the API call, we'll retrieve the value from the current PatchBaseline
            current_patch_baseline = client.get_patch_baseline(BaselineId=patch_baseline['patch_baseline_id'])
            response = client.update_patch_baseline(
                BaselineId=patch_baseline['patch_baseline_id'],
                ApprovalRules={
                    'PatchRules': [
                        {   
                            'PatchFilterGroup': {
                                'PatchFilters':
                                    current_patch_baseline['ApprovalRules']['PatchRules'][0]['PatchFilterGroup']['PatchFilters']
                            },
                            'ApproveAfterDays': approve_after_days,
                        },
                    ]
                },
            )

def run_patching_operation(session,operation, targets):
    client = session.client('ssm')
    response = client.send_command(
        Targets = [targets],
        DocumentName = 'AWS-RunPatchBaseline',
        TimeoutSeconds = 600,
        Comment = 'Executed by lambda',
        Parameters = {"Operation":[operation],"SnapshotId":[""]},
        MaxConcurrency = '25%',
        MaxErrors = '100%'
    )
    print("run_patching_operation retuned the command Id: {}".format(response['Command']['CommandId']))


def enable_wuauserv_service(session, tag_value):
    client = session.client('ssm')
    response1 = client.send_command(
        Targets=[
            {'Key':'tag:Platform', 'Values':['Windows']},
            {'Key':'tag:MaintenanceWindow', 'Values':[tag_value]}
        ],
        DocumentName = 'AWS-RunPowerShellScript',
        TimeoutSeconds = 600,
        Comment = 'Executed by patch manager through lambda',
        Parameters = {
			'commands': [
                "$Start_type=(Get-Service wuauserv | select-object -expandproperty StartType | ft -hidetableheaders)",
                "if($Start_type = \"Disabled\"){",
                "sc.exe config wuauserv start=demand",
                "} else {",
                " Write-Output $Start_type",
                "}",
                "$Start=(Get-Service wuauserv | select-object -expandproperty Status | ft -hidetableheaders)",
                "if($Start = \"Stopped\"){",
                " sc.exe start wuauserv",
                "} else {",
                " Write-Output $Start",
                "}"
			]
		},

        MaxConcurrency = '25%',
        MaxErrors = '100%'
    )
    print('wuauserv Status check returned the command Id: {}'.format(response1['Command']['CommandId']))
    
    
def lambda_handler(event, context):
    print("Received the event {}".format(event))
    operation = event['operation']
    windows_install_delay_days = event['windows_install_delay_days']
    windows_scan_delay_days = event['windows_scan_delay_days']
    rhel_install_delay_days = event['rhel_install_delay_days']
    rhel_scan_delay_days = event['rhel_scan_delay_days']
    current_date = datetime.date.today()
    targets = {}

    tenant_arn = os.environ['Tenant_Role_Arn']
    session = get_session(tenant_arn)
    
    print("Performing {} operation".format(operation))

    if (operation == 'Scan'):
        targets = {'Key': 'tag:Platform','Values': ['Windows', 'Linux']}
        update_patch_baselines(session,windows_scan_delay_days, rhel_scan_delay_days)
        print ("Scan targets key value is {}".format(targets))
        run_patching_operation(session,operation, targets)
    if (operation == 'Install'):
        tag_value = find_target_tag()
        targets = {'Key': 'tag:MaintenanceWindow','Values': [tag_value]}
        update_patch_baselines(session,windows_install_delay_days, rhel_install_delay_days)
        enable_wuauserv_service(session, tag_value)
        print ("Install targets key value is {}".format(targets))
        run_patching_operation(session,operation, targets)

        # Patch Group for Monthly patches where user has specified the week of the month
        week_number = get_week_number_of_month(current_date)
        monthly_tag_value = f"Monthly-{week_number}-{tag_value}"
        monthly_targets = {'Key': 'tag:MaintenanceWindow','Values': [monthly_tag_value]}
        enable_wuauserv_service(session, monthly_tag_value)
        print ("Montly install targets key value is {}".format(monthly_targets))
        run_patching_operation(session,operation, monthly_targets)

        # Only for first week of the month where user doesn't specify the week of the month
        if (first_week_of_month()):
            monthly_tag_value = 'Monthly-' + tag_value
            monthly_targets = {'Key': 'tag:MaintenanceWindow','Values': [monthly_tag_value]}
            enable_wuauserv_service(session, monthly_tag_value)
            print ("Montly install targets key value is {}".format(monthly_targets))
            run_patching_operation(session,operation, monthly_targets)
    
    return 'SUCCESS'
