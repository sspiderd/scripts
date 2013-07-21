'''
TODO
@author: Gil
'''
import subprocess, re,  logging, csv
import sys
import os
import datetime
from datetime import datetime, timedelta
import getopt
debug = False

if sys.version_info[0] == 2 and sys.version_info[1] >= 7:
# if we're on Python 2.7 or more, use OrderedDict from collections, otherwise require ordereddict module
    from collections import OrderedDict
else:
    from ordereddict import OrderedDict

period = 3600 #TODO: get from user

def write_to_csv(data, file_name, min_time, max_time):
    delta = timedelta(0,period)
    # start by writing the header, starting at min_time, advancing in period up until max_time    
    writer = csv.writer(open(file_name,'wb'), delimiter=',')
    header = ['what']
    curr_time = min_time
    while curr_time <= max_time:
        header.append(curr_time)
        curr_time += delta;
    writer.writerow(header)
    
    # now, for each instance, pad with '-' until we get to the first entry, then write values, than pad with more '-'
    for instance_id in data.keys():
        instance_data = data[instance_id]
        for metric in instance_data.keys():
            metric_data = instance_data[metric]
            curr_time = min_time
            row = []
            while curr_time < metric_data.keys()[0]:
                row.append('-') #
                curr_time += delta;
            row.extend(metric_data.values())
            writer.writerow([instance_id + "." + metric] + row)
            #todo: we should probably pad with '-' up until max
            

def usage():
    print "It's very simple, these arguments are mandatory:"
    print "-l --limit   = maximal number of VMs to take stats of"
    print "-s --start_date = start date for stats. format is YYYY-MM-DD"
    print "-e --end_date = end date for stats. format is YYYY-MM-DD"
    print ""
    print "Note to update the file aws_credentials to hold your AWS credentials"
    print ""
    print "This script was tested only on Linux. Use it on your own risk on different OSs"


def ec2_stats(limit, start_date, end_date):
    if debug:
        print "Running with limit = " + str(limit) + " start = " + start_date + " end = " + end_date
    args = ['./mon-list-metrics', '--aws-credential-file', './aws_credentials', '--namespace', '"AWS/EC2"',  '--metric-name', '"CPUUtilization"']
    p = subprocess.Popen(args, stdout=subprocess.PIPE)
    response = p.stdout.read()
    p.stdout.close()
    lines = response.strip().splitlines()
    instances = []
    for line in lines:
        m = re.search("{InstanceId=(.*?)}", line)
        if m is not None:
            instances.append(m.group(1))
            logging.debug('instance : '+ m.group(1))
                        
    # Now we have in instances the list of instance IDs, we can use
    # for now limit to 3 instances
    instances = instances[:limit]
    results = {}
    metrics = ['"CPUUtilization"', '"NetworkIn"', '"NetworkOut"']
    max_time = datetime.min
    min_time = datetime.max    
    # need to calculate min/max datetimes    
    for metric in metrics: 
        args = ['./mon-get-stats', '--aws-credential-file', './aws_credentials', '--namespace', '"AWS/EC2"',  '--metric-name', metric, '--start-time', start_date, '--end-time',end_date, '--period', str(period), '--statistics', "Average", '--dimensions']
        for instance_id in instances:
            print "Getting " + metric + " for " + instance_id
            if not results.has_key(instance_id):
                results[instance_id] = {} # create a new map for the results of this instance
            results[instance_id][metric] = OrderedDict()
            
            new_args = list(args)
            new_args.append('"InstanceId='+instance_id+'"')
            p = subprocess.Popen(args, stdout=subprocess.PIPE)
            response = p.stdout.read()
            lines = response.strip().splitlines()
            # first column is date, second is time, third is value, fourth is unit
            for line in lines:                
                values = line.split()
                curr_time = datetime.strptime(values[0] + " " + values[1], '%Y-%m-%d %H:%M:%S')
                if (curr_time > max_time):
                    max_time = curr_time
                if (curr_time < min_time):
                    min_time = curr_time
                    
                results[instance_id][metric][curr_time] = values[2]
    
    write_to_csv(results, './output.csv', min_time, max_time)

def verify_date_format(value, field_name):
    try:
        datetime.strptime(value, '%Y-%m-%d')
    except ValueError:
        print "Wrong format for "+field_name+", expect YYYY-MM-DD (e.g. 2012-02-24)"
        sys.exit(2)

def main(argv):
    
    try:
        opts, args = getopt.getopt(argv, "hlse:d", ["help", "limit=","start_date=", "end_date="])
    except getopt.GetoptError:           
        usage()                          
        sys.exit(2)
    limit = None
    start_date = None
    end_date = None
    for opt, arg in opts:                
        if opt in ("-h", "--help"):      
            usage()                     
            sys.exit()                  
        elif opt == '-d':
            global debug           
            debug = True            
        elif opt in ("-l", "--limit"): 
            limit = int(arg)
        elif opt in ("-s", "--start_date"):
            start_date = arg;
            verify_date_format(start_date, "start_date")
        elif opt in ("-e", "--end_date"):
            end_date = arg;
            verify_date_format(end_date, "end_date")
            
    if ((limit is None) or (start_date is None) or (end_date is None)):
        print "Wrong usage!"
        usage()
        sys.exit(2)
    # make sure the AWS_CLOUDWATCH_HOME env variable is defined correctly
    if not os.environ.has_key('AWS_CLOUDWATCH_HOME'):
        os.environ['AWS_CLOUDWATCH_HOME'] = os.environ['PWD']+'/..'
    
    # go for it
    ec2_stats(limit,start_date,end_date)
    
if __name__ == "__main__":
    main(sys.argv[1:])
            