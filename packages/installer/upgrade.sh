# e2label <part> <newlabel>
# tune2fs -L COS_ACTIVE $DEVICE


# 1. Identify active/passive partition
# 2. Install upgrade in passive partition
# 3. Invert partition labels
# 4. Update grub
# 5. Reboot if requested by user (?)

find_partitions() {
    ACTIVE=$(blkid -L COS_ACTIVE)
    if [ -z "$ACTIVE" ]; then
        echo "Active partition cannot be found"
        exit 1
    fi
    PASSIVE=$(blkid -L COS_PASSIVE)
    if [ -z "$ACTIVE" ]; then
        echo "Active partition cannot be found"
        exit 1
    fi
}

# cos-upgrade-image: system/cos
find_upgrade_channel() {
    UPGRADE_IMAGE=$(cat /etc/cos-upgrade-image)
    if [ -z "$UPGRADE_IMAGE" ]; then
        UPGRADE_IMAGE="system/cos"
        echo "Upgrade image not found in /etc/cos-upgrade-image, using $UPGRADE_IMAGE"
    fi
}

mount_image() {


}

upgrade() {
    mkdir /tmp/upgrade
    mount -t auto -o rw $PASSIVE /tmp/upgrade
    luet install -y $UPGRADE_IMAGE
}

find_partitions
find_upgrade_channel

