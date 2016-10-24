# ==============================================================================
# Hivent represents a significant historical happening (historical event).
# It is the only representation of the temporal dimension in the data model
# and therefore the main organisational dimension.
# An Hivent may contain one or many EditOperations to the areas of the world.
#
# ------------------------------------------------------------------------------
# Hivent 1:n EditOperation
#
# ==============================================================================

from django.db import models
from django.utils import timezone
from django.contrib import gis
from djgeojson.fields import *
from django.forms.models import model_to_dict


# ------------------------------------------------------------------------------
class Hivent(models.Model):

  name =        models.CharField      (max_length=150, default='')
  date =        models.DateTimeField  (default=timezone.now)
  location =    models.CharField      (null=True, max_length=150)
  description = models.CharField      (null=True, max_length=1000)
  link =        models.CharField      (null=True, max_length=300)


  # ============================================================================
  def __unicode__(self):
    return self.name


  # ============================================================================
  # givent set of validated (!) hivent data, update the Hivent properties
  # ============================================================================

  def update(self, hivent_data):

    ## save in database
    self.name =             hivent_data['name']                 # CharField
    self.date =             hivent_data['date']                 # DateTimeField
    self.location =         hivent_data['location']             # CharField
    self.description =      hivent_data['description']          # CharField
    self.link =             hivent_data['link']                 # CharField

    hivent.save()

    return hivent


  # ============================================================================
  # return Hivent with all its associated Changes
  # ============================================================================

  def prepare_output(self):

    from HistoGlobe_server.models import EditOperation, HiventOperation, OldArea, NewArea, UpdateArea
    from HistoGlobe_server import utils
    import chromelogger as console


    # get original Hivent with all properties
    # -> except for change
    hivent = model_to_dict(self)

    # get all EditOperations associated to the Hivent
    hivent['edit_operations'] = []
    for edit_operation_model in EditOperation.objects.filter(hivent=self):
      edit_operation = model_to_dict(edit_operation_model)

      # get all HiventOperations associated to the EditOperation
      edit_operation['hivent_operations'] = []
      for hivent_operation_model in HiventOperation.objects.filter(edit_operation=edit_operation_model):
        hivent_operation = model_to_dict(hivent_operation_model)

        # get all OldAreas, NewAreas and UpdateArea associated to the HiventOperation
        hivent_operation['old_areas'] = []
        hivent_operation['new_areas'] = []
        hivent_operation['update_area'] = None
        for old_area_model in OldArea.objects.filter(hivent_operation=hivent_operation_model):
          hivent_operation['old_areas'].append(model_to_dict(old_area_model))
        for new_area_model in NewArea.objects.filter(hivent_operation=hivent_operation_model):
          hivent_operation['new_areas'].append(model_to_dict(new_area_model))
        for update_area_model in UpdateArea.objects.filter(hivent_operation=hivent_operation_model):
          hivent_operation['update_area'] = model_to_dict(update_area_model)

        edit_operation['hivent_operations'].append(hivent_operation)
      hivent['edit_operations'].append(edit_operation)

    # prepare date for output
    hivent['date'] = utils.get_date_string(hivent['date'])

    return hivent


  # ============================================================================
  class Meta:
    ordering = ['-date']  # descending order (2000 -> 0 -> -2000 -> ...)
    app_label = 'HistoGlobe_server'
