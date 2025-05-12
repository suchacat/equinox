## obtain the heckin certifications from the keanu reeves 420 updoot kind stranger google
import std/[os, logging]
import pkg/db_connector/db_sqlite
import ./paths

type
  AndroidIdFetchFailed* = object of CatchableError
  IDNotStored* = object of AndroidIdFetchFailed
  InsufficientIDEntryError* = object of AndroidIdFetchFailed
  GSFNotInitialized* = object of AndroidIdFetchFailed

proc getGSFAndroidID*(user: string): string =
  let appDataPath = getAppDataPath(user, "com.google.android.gsf")
  if not dirExists(appDataPath):
    raise newException(
      GSFNotInitialized,
      "GSF has not been initialized yet. Has this container never booted before?",
    )

  let db = open(
    appDataPath / "databases" / "gservices.db",
    "",
    "",
    "",
  )
  let rows = db.getAllRows(sql"select * from main where name = 'android_id';")

  debug "certification: query rows count: " & $rows.len
  if rows.len < 1:
    raise newException(
      IDNotStored, "`android_id` key was not stored in GSF gservices database!"
    )

  if rows[0].len < 2 or rows[0].len > 2:
    raise newException(
      InsufficientIDEntryError,
      "Invalid row: length is either less than 2, or greater than 2. Either ways, it's malformed.",
    )

  rows[0][1]
