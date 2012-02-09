
class TestDiskUsage < MiniTest::Unit::TestCase

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
    assert (df["/dev/disk0s2"][:free] == 98)
    assert (df["/dev/disk4"][:usage] == 68)
  end

  def test_parse_linux
    output = <<-EOF
ilesystem           1G-blocks      Used Available Use% Mounted on
/dev/sda1                  10G        2G        9G  13% /
none                        8G        1G        8G   1% /dev
none                        8G        0G        8G   0% /dev/shm
none                        8G        1G        8G   1% /var/run
none                        8G        0G        8G   0% /var/lock
none                        8G        0G        8G   0% /lib/init/rw
/dev/md0                 1680G      163G     1517G  10% /mnt
EOF

    df = Hardware::Storage::DiskUsage.parse_output(output)
    assert (df["/dev/sda1"][:free] == 9)
    assert (df["/dev/md0"][:usage] == 10)
  end

  def test_parse_multiline
    output = <<-EOF
Filesystem           1G-blocks      Used Available Use% Mounted on
/dev/sda1                   8G        3G        6G  34% /
/dev/sdb                  827G        1G      785G   1% /mnt
none                       35G        0G       35G   0% /dev/shm
/dev/sdf1                 400G      234G      167G  59% /mnt/foobar
/dev/sdg1                 200G      105G       95G  53% /mnt/baz
/dev/sdh1                   1G        1G        1G  63% /mnt/nerf
/dev/mapper/vg0_db-lv0
                         7167G     1116G     6052G  16% /mnt/db
EOF

    df = Hardware::Storage::DiskUsage.parse_output(output)
    assert (df.values.size == 7)
    assert (df["/dev/sda1"][:free] == 6)
    assert (df["/dev/sdg1"][:used] == 105)
    assert (df["/dev/sdg1"][:mount] == "/mnt/baz")
    assert (df["/dev/mapper/vg0_db-lv0"][:size] == 7167)
  end


end
