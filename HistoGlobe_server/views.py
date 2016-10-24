"""
  This file contains all the views on the data in the database,
  i.e. this file defines the interface to the client application.
  - on init: get all areas of one time point (snapshot)
  - on run:  get all areas that change at hivent x
  - save hivent + changes
"""

# ==============================================================================
### INCLUDES ###

# Django
from django.http import HttpResponse
from django.shortcuts import render
from django.utils import timezone
from django.forms.models import model_to_dict

# GeoDjango
from django.contrib.gis.geos import Point

# utils
import chromelogger as console
import re
import json
import datetime

# own
from HistoGlobe_server.models import *
from HistoGlobe_server import utils


# ==============================================================================
"""
## INTERFACE ##
basic idea of client-server interaction
POST: client sends data to be processed by the server and awaits an answer
GET:  client requires data from the server and awaits an answer

# data structures
  client -> server (reuqest):
    - stringified JSON of arrays and objects (can be multi-dimensional)
      JSON.stringify request
      ->  access on the server by:
          json.loads(request.body)                    # needs: import json
  client <- server (response):
    - list or dictionary (no tuples or anything else, please!) stringified
      HttpResponse(json.dumps(response))
      ->  access on the client by:
          success: (reponse) =>
            data = $.parseJSON response


# date interoperabiliy: use RFC 3339 (date = 'YYYY-MM-DDTHH:MM:SS.sss+UTC')

  client -> server:
    moment(dateObject).format()           # needs: moment.js
    ->  access on the server by:
        iso8601.parse_date(date_string)   # needs: import iso8601
  client <- server:
    rfc3339(date_object)                  # needs: from rfc3339 import rfc3339
    ->  access on the client by:
        moment(dateString)
"""


# ==============================================================================
# simple view redirecting to index of HistoGlobe
# ==============================================================================

def index(request):
  return render(request, 'HistoGlobe_client/index.htm', {})


# ==============================================================================
# get all initial data (Hivents, Areas, Relations) from Server to Client
# quick and Dirty, but works fine for now
# ==============================================================================

def get_all(empty_request):

  response = {
    'hivents':            [],
    'areas':              [],
    'area_names':         [],
    'area_territories':   [],
    'territory_relation': []
  }


  # 1) get all Hivents
  for hivent in Hivent.objects.all():
    response['hivents'].append(hivent.prepare_output())

  # 2) get all Areas
  for area in Area.objects.all():
    response['areas'].append(model_to_dict(area))

  # 3) get all AreaNames
  for area_name in AreaName.objects.all():
    response['area_names'].append(model_to_dict(area_name))

  # 4) get all AreaTerritories
  for area_territory in AreaTerritory.objects.all():
    response['area_territories'].append(area_territory.prepare_output())

  # prepare and deliver everything to the client
  return HttpResponse(json.dumps(response))


# ==============================================================================
# save hivent and change to database
# return hivent and newly created area ids to client
# ==============================================================================

def save_operation(request):

  ### INIT VARIABLES ###

  # prepare output to response
  response = {
    'hivent':   {} ,   # dictionary of properties
    'edit_operation_id': None,  # int
    'hivent_operations': [
    # {
    #   'old_id':                 int
    #   'new_id':                 int
    #   'area_id':                int
    #   'new_area_name_id':       int
    #   'new_area_territory_id':  int
    # }
    ]
  }

  # load input from request
  request_data = json.loads(request.body)

  hivent_data =           request_data['hivent']
  hivent_is_new =         request_data['hivent_is_new']
  edit_operation_data =   request_data['edit_operation']
  new_areas =             request_data['new_areas']
  new_area_names =        request_data['new_area_names']
  new_area_territories =  request_data['new_area_territories']


  ### PROCESS HIVENT ###

  hivent = None

  # create new hivent
  if hivent_is_new == True:
    [validated_hivent_data, error_message] = utils.validate_hivent(hivent_data)
    # error handling
    if validated_hivent_data is False: return HttpResponse(error_message)
    hivent = Hivent(
        name =        validated_hivent_data['name'],           # CharField          (max_length=150)
        date =        validated_hivent_data['date'],           # DateTimeField      (default=timezone.now)
        location =    validated_hivent_data['location'],       # CharField          (null=True, max_length=150)
        description = validated_hivent_data['description'],    # CharField          (null=True, max_length=1000)
        link =        validated_hivent_data['link'],           # CharField          (max_length=300)
      )
    hivent.save()

  # or update existing hivent
  else:
    hivent = Hivent.objects.get(id=hivent_data['id'])
    [validated_hivent_data, error_message] = utils.validate_hivent(hivent_data)
    # error handling
    if validated_hivent_data is False: return HttpResponse(error_message)
    # update hivent
    hivent.update(validated_hivent_data)

  # add to output
  hivent_output = model_to_dict(hivent)
  hivent_output['date'] = utils.get_date_string(hivent_output['date'])
  response['hivent'] = hivent_output


  ### PROCESS EDIT OPERATION ###
  [h_operation, error_message] = utils.validate_historical_operation_id(edit_operation_data['operation'])
  edit_operation = EditOperation (
      hivent =    hivent,
      operation = h_operation
    )
  edit_operation.save()

  # add to output
  response['edit_operation_id'] = edit_operation.id


  ### PROCESS AREA CHANGES ###

  for hivent_operation_data in edit_operation_data['hivent_operations']:

    [operation, error_message] = utils.validate_area_operation_id(hivent_operation_data['operation'])

    ## get Area of the HiventOperation
    area = None

    # for 'ADD' changes, it is a new Area
    if operation == 'ADD':
      area = Area()
      area.save()
    # for all other changes, the Area already existed
    else:
      area = Area.objects.get(id=hivent_operation_data['area'])


    ## get AreaName of old and new HiventOperations

    old_area_name = None
    new_area_name = None

    # for 'DEL' and 'NCH' => old AreaName
    if (operation == 'DEL') or (operation == 'NCH'):
      old_area_name = AreaName.objects.get(id=hivent_operation_data['old_area_name'])

    # for 'ADD' and 'NCH' => new AreaName
    if (operation == 'ADD') or (operation == 'NCH'):
      # find the new AreaName
      for area_name_data in new_area_names:
        if area_name_data['id'] == hivent_operation_data['new_area_name']:
          # validate and save it
          [area_name_data, error_message] = utils.validate_name(area_name_data)
          new_area_name = AreaName (
              area          = area,
              short_name    = area_name_data['short_name'],
              formal_name   = area_name_data['formal_name']
            )
          new_area_name.save()


    ## get AreaTerritory of old and new HiventOperations

    old_area_territory = None
    new_area_territory = None

    # for 'DEL' and 'TCH' => old AreaTerritory
    if (operation == 'DEL') or (operation == 'TCH'):
      old_area_territory = AreaTerritory.objects.get(id=hivent_operation_data['old_area_territory'])

    # for 'ADD' and 'TCH' => new AreaTerritory
    if (operation == 'ADD') or (operation == 'TCH'):
      # find the new AreaTerritory
      for area_territory_data in new_area_territories:
        if area_territory_data['id'] == hivent_operation_data['new_area_territory']:
          # validate and save it
          [area_territory_data, error_message] = utils.validate_territory(area_territory_data)
          new_area_territory = AreaTerritory (
              area                  = area,
              geometry              = area_territory_data['geometry'],
              representative_point  = area_territory_data['representative_point']
            )
          new_area_territory.save()

    # create new HiventOperation
    hivent_operation = HiventOperation(
        edit_operation =   edit_operation,
        operation =           operation,
        area =                area,
        old_area_name =       old_area_name,
        new_area_name =       new_area_name,
        old_area_territory =  old_area_territory,
        new_area_territory =  new_area_territory
      )
    hivent_operation.save()

    # HiventOperation <- Area
    if operation == 'ADD':
      area.start_change = hivent_operation
      area.save()

    elif operation == 'DEL':
      area.end_change = hivent_operation
      area.save()

    # HiventOperation <- AreaName
    if old_area_name:
      old_area_name.end_change = hivent_operation
      old_area_name.save()

    if new_area_name:
      new_area_name.start_change = hivent_operation
      new_area_name.save()

    # HiventOperation <- AreaTerritory
    if old_area_territory:
      old_area_territory.end_change = hivent_operation
      old_area_territory.save()

    if new_area_territory:
      new_area_territory.start_change = hivent_operation
      new_area_territory.save()

    # add to output

    # this is so ugly... doesn't that go easier?
    new_area_name_id = None
    if new_area_name: new_area_name_id = new_area_name.id
    new_area_territory_id = None
    if new_area_territory: new_area_territory_id = new_area_territory.id

    hivent_operation_dict = {
      'old_id':                 hivent_operation_data['id'],
      'new_id':                 hivent_operation.id,
      'area_id':                area.id,
      'new_area_name_id':       new_area_name_id,
      'new_area_territory_id':  new_area_territory_id
    }
    response['hivent_operations'].append(hivent_operation_dict)


  ### OUTPUT ###

  return HttpResponse(json.dumps(response))  # N.B: mind the HttpResponse(function)