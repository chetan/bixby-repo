
require "helper"

class TestDiskUsage < Bixby::TestCase

  def test_parse_mac
    output = <<-EOF
Filesystem    1G-blocks Used Available Capacity  Mounted on
/dev/disk0s2        297  198        98    67%    /
devfs                 0    0         0   100%    /dev
/dev/disk1s2       1719  643      1076    38%    /Volumes/Foobar
/dev/disk4         1862 1259       603    68%    /Volumes/Baz
map -hosts            0    0         0   100%    /net
map auto_home         0    0         0   100%    /home
EOF

    df = Hardware::Storage::DiskUsage.parse_output(output)
    Hardware::Storage::DiskUsage.add_mount_types(df)

    assert_equal 6, df.values.size
    assert (df["/"][:free] == 98)
    assert (df["/Volumes/Baz"][:usage] == 68)
    assert (df["/"][:type] == "hfs")
  end

  def test_parse_mac_inodes
    output = <<-EOF
Filesystem    1G-blocks Used Available Capacity   iused     ifree %iused  Mounted on
/dev/disk0s2        237  204        33    87%  53643493   8661377   86%   /
devfs                 0    0         0   100%       714         0  100%   /dev
/dev/disk1s2       1719  941       777    55% 246926681 203930088   55%   /Volumes/Foobar
/dev/disk4         1862 1419       443    77% 372154542 116140120   76%   /Volumes/Baz
map -hosts            0    0         0   100%         0         0  100%   /net
map auto_home         0    0         0   100%         0         0  100%   /home
EOF

    df = Hardware::Storage::DiskUsage.parse_output(output)
    Hardware::Storage::DiskUsage.add_mount_types(df)

    assert_equal 6, df.values.size
    assert (df["/"][:free] == 33)
    assert (df["/Volumes/Baz"][:usage] == 77)
    assert (df["/"][:type] == "hfs")
  end

  def test_parse_linux
    output = <<-EOF
Filesystem    Type   1G-blocks      Used Available Use% Mounted on
/dev/sda1     ext3         10G        8G        3G  79% /
none      devtmpfs          4G        1G        4G   1% /dev
none         tmpfs          4G        0G        4G   0% /dev/shm
none         tmpfs          4G        1G        4G   1% /var/run
none         tmpfs          4G        0G        4G   0% /var/lock
none         tmpfs          4G        0G        4G   0% /lib/init/rw
/dev/sdb      ext3        414G      239G      155G  61% /mnt
EOF

    df = Hardware::Storage::DiskUsage.parse_output(output)

    assert_equal 7, df.values.size
    assert (df["/"][:free] == 3)
    assert (df["/mnt"][:usage] == 61)
    assert (df["/"][:type] == "ext3")
  end

  def test_parse_multiline
    output = <<-EOF
Filesystem    Type   1G-blocks      Used Available Use% Mounted on
/dev/sda1     ext3          8G        3G        5G  36% /
/dev/sdb      ext3        827G        1G      785G   1% /mnt
none         tmpfs         35G        0G       35G   0% /dev/shm
/dev/sdf1      xfs        400G        1G      400G   1% /mnt/foobar
/dev/sdg1      xfs        200G      116G       85G  58% /mnt/baz
/dev/sdh1      xfs          1G        1G        1G  63% /mnt/bar
/dev/mapper/vg0_db-lv0
               xfs       7167G     1440G     5727G  21% /mnt/nerf
EOF

    df = Hardware::Storage::DiskUsage.parse_output(output)

    assert_equal 7, df.values.size
    assert (df["/"][:free] == 5)
    assert (df["/mnt/baz"][:used] == 116)
    assert (df["/mnt/baz"][:mount] == "/mnt/baz")
    assert (df["/mnt/nerf"][:size] == 7167)
    assert (df["/mnt/nerf"][:type] == "xfs")
  end


end
