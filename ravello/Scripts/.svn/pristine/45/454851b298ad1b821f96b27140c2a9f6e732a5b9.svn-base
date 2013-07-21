'''

This script will get a volume as parameter, it will locate the instance id of the current machine 
then it will clone the volume and attach it to the image
neat, ha?

Notes: This script only works on linux with python installed (duh), and will only work from within the amazon cloud

@author: Ilan NG
'''
import shlex, subprocess, time, re, sys, getopt, os

debug = False

def print_command(args):
    command = ','.join(str(n) for n in args).replace(",", " ")
    if debug: print "Sending command: " + command


def find_available_device():
    """
    Start with /dev/sdf, enumerate hard drives until a valid device is found
    """
    ids = ['h', 'i', 'j', 'k', 'l', 'm', 'n']
    for device_id in ids:
        if not os.path.lexists('/dev/sd'+device_id) and not os.path.lexists('/dev/xvd'+device_id):
            return device_id
    raise "No available device"

def wait_for_snapshot_to_finish(snap_id):
    snapshotComplete = False
    args = ['ec2-describe-snapshots', snap_id]
    while not snapshotComplete:
        if debug: print 'Waiting for snapshot to complete...'
        if debug: print_command(args)
        p = subprocess.Popen(args, stdout=subprocess.PIPE)
        snapshotResponse = p.stdout.read()
        p.stdout.close()
        if debug: print snapshotResponse
        if shlex.split(snapshotResponse)[3] == 'completed':
            snapshotComplete = True
            if debug: print 'snapshot Complete'
            break
        time.sleep(2)

def clone_ebs(volumeToSnapshot, mount_point):
    
    #get instance Id
    args = ['wget', '-q', '-O', '-', 'http://169.254.169.254/latest/meta-data/instance-id']
    if debug: print_command(args)
    p = subprocess.Popen(args, stdout=subprocess.PIPE)
    response = p.stdout.read()
    p.stdout.close()
    instanceToAttachTo = response ;
    
    if debug: print "starting: attaching volume " + volumeToSnapshot + " to instance " + instanceToAttachTo
    if debug: print ""
    
    args = ['ec2-describe-instances']
    if debug: print_command(args)
    p = subprocess.Popen('ec2-describe-instances', stdout=subprocess.PIPE)
    response = p.stdout.read()
    p.stdout.close()
    m = re.search('INSTANCE\t'+instanceToAttachTo+'.*\d+-\d+-\d+T\d+:\d+:\d+\+\d+\t(.*?)\t.*', response) ;
    zone = m.group(1)
    
    #should first decide if should create a snapshot, or just create a new volume from the snapshot
    args = ['ec2-describe-snapshots']
    if debug: print_command(args)
    p = subprocess.Popen(args, stdout=subprocess.PIPE)
    response = p.stdout.read()
    p.stdout.close()
    m = re.search('SNAPSHOT\t(.*?)\t.*'+volumeToSnapshot+'\t(.*?)\t.*', response)
    if m == None:
        # should create the snapshot, no snapshot ready
        if debug: print('creating new snapshot for volume')
        args = ['ec2-create-snapshot', volumeToSnapshot]
        if debug: print_command(args)
        p = subprocess.Popen(args, stdout=subprocess.PIPE)
        snapshotResponse = p.stdout.read()
        p.stdout.close()
        
        if debug: print snapshotResponse
        
        #Get the snapshot id
        snapshotId = shlex.split(snapshotResponse)[1]
        if debug: print 'creating snapshot ' + snapshotId
        
        #This snapshot is now in pending form, i'll need to wait for it to complete
        wait_for_snapshot_to_finish(snapshotId)
    else:
        snapshotId = m.group(1)   
        if (m.group(2) == 'completed'):
            # if the snapshot is in completed state, should simply create a volume
            pass
        else:
            # should wait for the snapshot to finish
            wait_for_snapshot_to_finish(snapshotId)
            pass
    
    #Create the volume and take its ID
    if debug: print 'creating volume from snapshot...'
    args = ['ec2-create-volume', '-z', zone, '--snapshot', snapshotId]
    if debug: print_command(args)
    p = subprocess.Popen(args, stdout=subprocess.PIPE)
    response = p.stdout.read()
    p.stdout.close()
    volume = shlex.split(response)[1]

    if debug: print 'volume is being created: ' + volume
    if debug: print response
    
    volumeCreationComplete = False
    args = ['ec2-describe-volumes']
    while not volumeCreationComplete:
        if debug: print 'Waiting for volume to become available...'
        if debug: print_command(args)
        p = subprocess.Popen(args, stdout=subprocess.PIPE)
        response = p.stdout.read()
        p.stdout.close()
        if debug: print response
        m = re.search('VOLUME\t' + volume + '.*' + zone + '\t(.*?)\t', response)
        if (m.group(1) == 'available'):
            volumeCreationComplete = True
            if debug: print 'volume ' + volume + ' is now available'
            break
        time.sleep(2)
    
    device_id = find_available_device();
    
    #Attach the volume to the ec2 machine
    args = ['ec2-attach-volume', '-d', '/dev/sd'+device_id, '-i', instanceToAttachTo, volume]
    if debug: print_command(args)
    p = subprocess.Popen(args)
    
    #Wait for it to become actually attached
    volumeAttachmentComplete = False
    args = ['ec2-describe-volumes']
    while not volumeAttachmentComplete:
        if debug: print 'Waiting for volume to become attached...'
        if debug: print_command(args)
        p = subprocess.Popen(args, stdout=subprocess.PIPE)
        response = p.stdout.read()
        p.stdout.close()
        if debug: print response
        m = re.search('ATTACHMENT\t' + volume + '.*'+'/dev/sd'+device_id+'\t(.*?)\t', response)
        if m == None: continue
        if (m.group(1) == 'attached'):
            volumeAttachmentComplete = True
            if debug: print 'volume ' + volume + ' is now attached'
            break
        time.sleep(2)
    
    if debug: print 'volume attached'
    # device id for mounting is actually /dev/xvd 
    # wait for 5 seconds for linux to refresh devices
    time.sleep(5)
    
    # if there is a real partition (e.g. /dev/xvdi1 and not /dev/xvdi) should use it instead    
    if os.path.lexists('/dev/xvd'+device_id+'1'):
        device_id = device_id+'1'
    
    args = ['sudo', 'sh', '-c', 'echo '+'/dev/xvd'+device_id + ' ' + mount_point + ' ext4 noatime 0 0 >> /etc/fstab']
    if debug: print_command(args)
    p = subprocess.Popen(args)
    
    args = ['sudo', 'mkdir', mount_point]
    if debug: print_command(args)
    p = subprocess.Popen(args)
    
    # wait for 5 seconds for linux to refresh fstab
    time.sleep(5)
    
    args = ['sudo', 'mount', '-a']
    if debug: print_command(args)
    p = subprocess.Popen(args)
    
    # wait until the mount is completed    
    while True:
        if len(os.listdir(mount_point)) == 0:
            # can't see files in the directory, sleep for 5 seconds
            time.sleep(5)
        else:
            break
    
    if debug: print 'volume mounted (or not)'
    
def usage():
    print "It's very simple, these arguments are mandatory:"
    print "-v --volume   = the volume that we want to clone and attach"
    print "-m --mount_point = the mount point to create for the attached volume"
    print ""
    print "This one isn't:"
    print "-d            = print debug stuff"
    print ""
    print "Note that this process needs to be run by a sudoer"
    print "Also note that environment variables 'EC2_HOME', 'EC2_PRIVATE_KEY' and 'EC2_CERT' must be set"


def main(argv):
    volume = ""
    mount_point = ""
    
    try:                                
        opts, args = getopt.getopt(argv, "hvm:d", ["help", "volume=","mount_point="]) 
    except getopt.GetoptError:           
        usage()                          
        sys.exit(2)  
    for opt, arg in opts:                
        if opt in ("-h", "--help"):      
            usage()                     
            sys.exit()                  
        elif opt == '-d':
            global debug           
            debug = True            
        elif opt in ("-v", "--volume"): 
            volume = arg
        elif opt in ("-m", "--mount_point"):
            mount_point = arg;
    if (volume == "" or mount_point == ""):
        usage()
        sys.exit(2)
    clone_ebs(volume, mount_point) ;        

if __name__ == "__main__":
    main(sys.argv[1:])