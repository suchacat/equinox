## obtain the heckin certifications from the keanu reeves 420 updoot kind stranger google
import std/[browsers, logging]
import ./[lxc, sugar]

proc getGSFAndroidID*: string =
  &runCmdInContainer("sqlite3 /data/data/com.google.android.gsf/databases/gservices.db \"select * from main where name = 'android_id';\"")
