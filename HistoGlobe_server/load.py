"""
  This file does all the initialization work for the database:
  - create inital set of Areas of the world in in year 2015.
  - create initial snapshot for the year 2015
  - populate representative_point field in area table

  Caution: This can be performed ONLY in the beginning, when it is clear that
  all areas in the database are actually active in 2015. As soon as the first
  historical country is added, this script is not usable anymore.

  how to run:
  -----------

sudo su postgres
psql
CREATE DATABASE histoglobe_database;
CREATE USER HistoGlobe_user WITH PASSWORD '12345';
ALTER ROLE HistoGlobe_user SET client_encoding TO 'utf8';
ALTER ROLE HistoGlobe_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE HistoGlobe_user SET timezone TO 'UTC';
\c histoglobe_database
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION postgis_tiger_geocoder;
\q
exit

## load model migrate
python manage.py makemigrations
python manage.py migrate

## prepare
python manage.py shell
from HistoGlobe_server import load
load.run()

"""


# ==============================================================================
### INCLUDES ###

# general python modules
import os
import csv
import json
import iso8601      # for date string -> date object

# GeoDjango
from django.contrib.gis.utils import LayerMapping
from django.contrib.gis.geos import *

# own
import HistoGlobe_server
from models import *



# ==============================================================================
### VARIABLES ###

countries_full =    'ne_10m_admin_0_countries.geojson'   # source: Natural Earth Data
countries_reduced = 'ne_50m_admin_0_countries.geojson'   # source: Natural Earth Data

init_data_version_date = '2014-10-10'

LNG_MAX = 180.0
LAT_MAX =  90.0


# ------------------------------------------------------------------------------
def get_file(file_id):
  return os.path.abspath(os.path.join(
      os.path.dirname(HistoGlobe_server.__file__),
      'data/init_area_data/',
      file_id
    )
  )

# ------------------------------------------------------------------------------
def get_init_countries_file():
  return os.path.abspath(os.path.join(
      os.path.dirname(HistoGlobe_server.__file__),
      'data/init_source_areas',
      countries_reduced
    )
  )




# ==============================================================================
### MAIN FUNCTION ###
# TODO: automate this using: psycopg2

def run(verbose=True):


  ### CLEANUP ###

  Hivent.objects.all().delete()
  Area.objects.all().delete()
  print('All objects deleted from database')


  ### INIT AREAS ###

  ## init universe (omega)
  universe = Area(
      universe = True
    )
  universe.save()

  # initial territory: full world
  # -> omitted for now, because it is not necessary, it will not be shown anyway
  # full_world_dimension = MultiPolygon(((
  #     (-LNG_MAX, -LAT_MAX),
  #     (-LNG_MAX,  LAT_MAX),
  #     ( LNG_MAX,  LAT_MAX),
  #     ( LNG_MAX, -LAT_MAX),
  #     (-LNG_MAX, -LAT_MAX)
  #   )))
  # universe_territory = AreaTerritory(
  #     area =      universe,
  #     geometry =  full_world_dimension
  #   )
  # universe_territory.save()

  # the universe has no name

  print("Universe Area created")


  ## load initial areas from shapefile
  # distribute into the three tables

  json_data_string = open(get_init_countries_file())
  json_data = json.load(json_data_string)

  for feature in json_data['features']:
    short_name = feature['properties']['name_long']
    formal_name = feature['properties']['formal_en']
    if formal_name is None: formal_name = short_name
    geometry = GEOSGeometry(json.dumps(feature['geometry']))

    area = Area()
    area.save()

    area_territory = AreaTerritory(
        area =      area,
        geometry =  geometry
      )
    area_territory.save()

    area_name = AreaName(
        area =        area,
        short_name =  short_name,
        formal_name = formal_name
      )
    area_name.save()

    print("Area " + short_name + " created")


  ## update properties of initial areas
  ## and make creation hivent for this area

  with open(get_file('areas_to_update.csv'), 'r') as in_file:
    reader = csv.DictReader(in_file, delimiter='|', quotechar='"')
    for row in reader:

      # get area objects
      area_name =       AreaName.objects.get(short_name=row['init_source_name'])
      area =            area_name.area
      area_territory =  AreaTerritory.objects.get(area=area)

      # update area
      area_name.short_name =    row['short_name'].decode('utf-8')
      area_name.formal_name =   row['formal_name'].decode('utf-8')
      area_name.save()

      print("Area " + str(area.id) + ': ' + area_name.short_name + " updated")

      # create hivent + change
      creation_date = iso8601.parse_date(row['creation_date'])
      hivent = Hivent(
          name = str(row['hivent_name']),
          date = creation_date
        )
      hivent.save()

      # Edit Operation: Create
      edit_operation = EditOperation(
          hivent =    hivent,
          operation = 'CRE'
        )
      edit_operation.save()

      # Hivent Operation: Secession from the universe
      hivent_operation = HiventOperation(
          edit_operation =   edit_operation,
          operation =        'SEC'
        )
      hivent_operation.save()

      # universe does not update its territory (yet)
      update_area = UpdateArea(
          hivent_operation = hivent_operation,
          area = universe
        )
      update_area.save()

      new_area = NewArea(
          hivent_operation =  hivent_operation,
          area =              area,
          name =              area_name,
          territory =         area_territory
        )
      new_area.save()

      print("Hivent " + hivent.name + " saved")


  ## delete areas

  with open(get_file('areas_to_delete.csv'), 'r') as in_file:
    reader = csv.DictReader(in_file, delimiter='|', quotechar='"')
    for row in reader:
      area_name = AreaName.objects.get(short_name=row['init_source_name'])
      area = area_name.area
      area.delete()

      print("Area " + area_name.short_name + " deleted")


  ## create new areas

  with open(get_file('areas_to_create.csv'), 'r') as in_file:
    reader = csv.DictReader(in_file, delimiter='|', quotechar='"')
    for row in reader:

      # get geometry from source file
      with open(get_file(row['source'])) as geom_source_file:
        new_geom_json = json.load(geom_source_file)
        new_geom_string = json.dumps(new_geom_json)

        # geometry of the seceded territory after SEC operation
        new_sec_geom = GEOSGeometry(new_geom_string)
        if new_sec_geom.geom_type != 'MultiPolygon':
          new_sec_geom = MultiPolygon(new_sec_geom)

        # create area, name and territory
        new_sec_area = Area()
        new_sec_area.save()

        new_sec_area_territory = AreaTerritory (
            area =          new_sec_area,
            geometry =      new_sec_geom
          )
        new_sec_area_territory.save()

        new_sec_area_name = AreaName (
            area =          new_sec_area,
            short_name =    row['short_name'].decode('utf-8'),
            formal_name =   row['formal_name'].decode('utf-8')
          )
        new_sec_area_name.save()


        # dissolve operation: secede territory as new Area from homeland
        if row['edit_operation'] == 'DIS':

          # get home area
          home_area_name = AreaName.objects.get(short_name=row['old_area'])
          home_area = home_area_name.area
          old_home_area_territory = AreaTerritory.objects.filter(area=home_area).last()

          # geometry of homeland before SEC operation
          old_home_geom = old_home_area_territory.geometry

          # geometry of homeland after SEC operation
          new_home_geom = old_home_geom.difference(new_sec_geom)
          if new_home_geom.geom_type != 'MultiPolygon':
            new_home_geom = MultiPolygon(new_home_geom)

          # geometry of secession country after SEC operation
          new_sec_geom = new_sec_geom.intersection(old_home_geom)
          if new_sec_geom.geom_type != 'MultiPolygon':
            new_sec_geom = MultiPolygon(new_sec_geom)
          new_sec_area_territory.geometry = new_sec_geom
          new_sec_area_territory.save()

          # create new territory of homeland
          new_home_area_territory = AreaTerritory(
              area =      home_area,
              geometry =  new_home_geom
            )
          new_home_area_territory.save()

          # create hivent + change
          creation_date = iso8601.parse_date(row['creation_date'])
          hivent = Hivent(
              name =        str(row['hivent_name']),
              date =        creation_date,
            )
          hivent.save()

          # Edit Operation: Dissolve
          edit_operation = EditOperation(
              hivent =    hivent,
              operation = 'DIS'
            )
          edit_operation.save()

          # Hivent Operation: Secession from homeland
          hivent_operation = HiventOperation(
              edit_operation =  edit_operation,
              operation =       'SEC'
            )
          hivent_operation.save()

          update_area = UpdateArea(
              hivent_operation =  hivent_operation,
              area =              home_area,
              old_territory =     old_home_area_territory,
              new_territory =     new_home_area_territory
            )
          update_area.save()

          new_area = NewArea (
              hivent_operation =  hivent_operation,
              area =              new_sec_area,
              name =              new_sec_area_name,
              territory =         new_sec_area_territory
            )
          new_area.save()

          print(new_sec_area_name.short_name + " separated from " + home_area_name.short_name + " by start hivent " + hivent.name)


        # create operation: secede territory from universe
        # -> omitted for now, so just simply create it new
        elif row['edit_operation'] == 'CRE':

          creation_date = iso8601.parse_date(row['creation_date'])
          hivent = Hivent(
              name =  str(row['hivent_name']),
              date =  creation_date,
            )
          hivent.save()

          edit_operation = EditOperation(
              hivent =    hivent,
              operation = 'CRE'
            )
          edit_operation.save()

          # Hivent Operation: Secession from universe
          hivent_operation = HiventOperation(
              edit_operation =  edit_operation,
              operation =       'SEC'
            )
          hivent_operation.save()

          update_area = UpdateArea(
              hivent_operation =  hivent_operation,
              area =              universe
            )
          update_area.save()

          new_area = NewArea (
              hivent_operation =  hivent_operation,
              area =              new_sec_area,
              name =              new_sec_area_name,
              territory =         new_sec_area_territory
            )
          new_area.save()


  ## merge areas that are parts of another area

  with open(get_file('areas_to_merge.csv'), 'r') as in_file:
    reader = csv.DictReader(in_file, delimiter='|', quotechar='"')
    for row in reader:

      # unify if part of another country
      if (row['part_of'] != ''):

        # get areas
        home_area_name =      AreaName.objects.get(short_name=row['part_of'])
        home_area =           home_area_name.area
        home_area_territory = AreaTerritory.objects.get(area=home_area)

        part_area_name =      AreaName.objects.get(short_name=row['init_source_name'])
        part_area =           part_area_name.area
        part_area_territory = AreaTerritory.objects.get(area=part_area)

        # update geometry
        union_geom = home_area_territory.geometry.union(part_area_territory.geometry)
        if union_geom.geom_type != 'MultiPolygon':
          union_geom = MultiPolygon(union_geom)

        # update / delete areas
        home_area_territory.geometry = union_geom
        home_area_territory.save()
        part_area.delete()
        print(part_area_name.short_name + " was incorporated into " + home_area_name.short_name)


      # handle as normal area if it is territory of another country
      # TODO: when hierarchies of Areas are introduced, handle these cases accordingly
      elif (row['territory_of'] != ''):

        # get areas
        home_area_name =      AreaName.objects.get(short_name=row['territory_of'])
        home_area =           home_area_name.area
        home_area_territory = AreaTerritory.objects.get(area=home_area)

        terr_area_name =      AreaName.objects.get(short_name=row['init_source_name'])
        terr_area =           terr_area_name.area
        terr_area_territory = AreaTerritory.objects.get(area=terr_area)

        # update areas
        terr_area_name.short_name =   row['short_name'].decode('utf-8')    # encoding problem :/
        terr_area_name.formal_name =  row['formal_name'].decode('utf-8')   # encoding problem :/
        terr_area_name.save()

        # add as NewArea to their creation event (SEC from universe)
        hivent_operation = NewArea.objects.get(area=home_area).hivent_operation

        new_area = NewArea (
            hivent_operation =  hivent_operation,
            area =              terr_area,
            name =              terr_area_name,
            territory =         terr_area_territory
          )

        print(terr_area_name.short_name + " added to creation hivent of " + home_area_name.short_name)


  ### CREATE REPRESENTATIVE POINTS ###

  for area_territory in AreaTerritory.objects.all():
    area_territory.representative_point = area_territory.geometry.point_on_surface
    area_territory.save()
  print("representative point calculated for all areas")

  # print("Snapshot created for date: " + snapshot.date.strftime('%Y-%m-%d'))
