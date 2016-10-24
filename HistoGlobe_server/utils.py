"""
  This file contains all kinds of universal helper functions
  - date object <-> date string conversion
  - date, string, url and geometry validation
"""

# ==============================================================================
### INCLUDES ###

# Django
from django.core.validators import URLValidator
from django.core.exceptions import ValidationError
from django.forms.models import model_to_dict

# GeoDjango
from django.contrib.gis.geos import WKTReader, MultiPolygon, Point
from django.contrib.gis import measure

# date & time
import datetime
import rfc3339      # for date object -> date string
import iso8601      # for date string -> date object

# utils
import chromelogger as console

# own
from HistoGlobe_server.models import *



################################################################################
#                    APPLICATION SPECIFIC UTIL FUNCTIONS                       #
################################################################################

# ==============================================================================
# receive an hivent dictionary with all properties
# validate each property based on their characteristics
# return hivent and validated? True/False
# ==============================================================================

def validate_hivent(hivent):

  ## name

  if validate_string(hivent['name']) is False:
    return [False, ("The name of the Hivent is not valid")]


  ## dates

  # start date has to be valid
  if validate_date(hivent['date']) is False:
    return [False, ("The date of the Hivent is not valid")]
    # else: date is OK
  hivent['date'] = get_date_object(hivent['date'])

  ## location

  # location name can be either a string or None
  if 'location' in hivent:
    if validate_string(hivent['location']) is False:
      return [False, ('The location name you were giving to the Hivent is not valid')]
    # else: location is ok

  else:
    hivent['location'] = None


  ## description
  # description can be either a string or None

  if 'description' in hivent:
    if validate_string(hivent['description']) is False:
      return [False, ('The description you were giving to the Hivent is not valid')]
    # else: description is ok

  else:
    hivent['description'] = None


  ## link
  # link can be either a valid URL or None
  hivent['link'] = validate_url(hivent['link'])

  # everything is fine => return hivent
  return [hivent, None]


# ==============================================================================
# given AreaTerritory / AreaName data, validate each datum
# ==============================================================================

def validate_territory(area_territory):

  # geometry
  area_territory['geometry'] = validate_geometry(area_territory['geometry'])
  if area_territory['geometry'] == False:
    return [False, ('The geometry of the AreaTerritory is not valid')]

  # representative point
  area_territory['representative_point'] = validate_point(area_territory['representative_point'])
  if area_territory['representative_point'] == False:
    return [False, ('The representative point of the AreaTerritory is not valid')]

  return [area_territory, None]


# ------------------------------------------------------------------------------
def validate_name(area_name):

  # short name
  area_name['short_name'] = validate_string(area_name['short_name'])
  if area_name['formal_name'] == False:
    return [False, ('The short name of the AreaName is not valid')]

  # formal name
  area_name['formal_name'] = validate_string(area_name['formal_name'])
  if area_name['short_name'] == False:
    return [False, ('The formal name of the AreaName is not valid')]

  # everything is fine
  return [area_name, None]


# ==============================================================================
# given operation id, make sure it is supported
# ==============================================================================

def validate_historical_operation_id(operation_id):

  # test if string
  operation_id = validate_string(operation_id)
  if operation_id == False:
    return [False, ('The operation id is not a string')]

  # test if id is valid
  valid_ids = ['CRE', 'UNI', 'INC', 'SEP', 'SEC', 'TCH', 'BCH', 'NCH', 'ICH', 'DES']
  if not any(operation_id in i for i in valid_ids):
    return [False, ('The operation id ' + operation_id + ' is not supported')]

  # everything is fine
  return [operation_id, None]

# ------------------------------------------------------------------------------
def validate_area_operation_id(operation_id):

  # test if string
  operation_id = validate_string(operation_id)
  if operation_id == False:
    return [False, ('The operation id is not a string')]

  # test if id is valid
  valid_ids = ['ADD', 'TCH', 'NCH', 'DEL']
  if not any(operation_id in i for i in valid_ids):
    return [False, ('The operation id ' + operation_id + ' is not supported')]

  # everything is fine
  return [operation_id, None]


################################################################################
#                           GENERAL UTIL FUNCTIONS                             #
################################################################################



# ==============================================================================
# dates: date string <-> date object, date string validation

# ------------------------------------------------------------------------------
def get_date_object(date_string):
  return iso8601.parse_date(date_string)

# ------------------------------------------------------------------------------
def get_date_string(date_object):
  return rfc3339.rfc3339(date_object)

# ------------------------------------------------------------------------------
def validate_date(date_string):
  try:
    get_date_object(date_string)
  except ValueError:
    return None

  # everything is fine
  return date_string


# ==============================================================================
# strings and urls: get_date_object(date_string)

# ------------------------------------------------------------------------------
def validate_string(in_string):
  if not isinstance(in_string, basestring):
    return ("Not a string")
  if in_string is '':
    return None

  # everything is fine
  return in_string

# ------------------------------------------------------------------------------
def validate_url(in_url):
  validate = URLValidator()
  try:
    validate(in_url)
  except ValidationError:
    return False

  # everything is fine
  return in_url

# ==============================================================================
# area: id validation

# ------------------------------------------------------------------------------
def validate_area_id(in_num):
  if not isinstance(in_num, (int, long)):
    return False
  # is id unique?
  if (len(Area.objects.filter(id=in_num)) != 1):
    return False

  # everything is fine
  return in_num


# ==============================================================================
# geometry: validation

# ------------------------------------------------------------------------------
# problem: output MUST be a MultiPolygon!
def validate_geometry(in_geom):
  wkt_reader = WKTReader()
  try:
    geom = wkt_reader.read(in_geom)
    if geom.geom_type != 'MultiPolygon':
      geom = MultiPolygon(geom)

  except ValueError:
    return False

  # everything is fine
  return geom


# ------------------------------------------------------------------------------
def validate_point(in_point):
  wkt_reader = WKTReader()
  try:
    point = wkt_reader.read(in_point)
  except ValueError:
    return [False]

  lng = point.x
  lat = point.y

  # check for correct interval
  if (lat < -90) or (lat > 90):
    return [False]
  if (lng < -180) or (lng > 180):
    return [False]

  # everything is fine
  return point

# ==============================================================================
# timestamp framework
# import time
# t1 = time.time()
# t2 = time.time()
# t3 = time.time()
# t4 = time.time()

# console.log(
#   t2-t1,
#   t3-t2,
#   t4-t3,
# )