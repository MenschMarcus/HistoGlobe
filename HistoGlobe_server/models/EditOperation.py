# ==============================================================================
# An EditOperation is one high-level change that has occured to a set of
# Areas in history. It belongs to exactly one Hivent.
# A set of low-level HiventOperations will be referenced to this EditOperation
#
# ------------------------------------------------------------------------------
# EditOperation n:1 Hivent
# EditOperation 1:n HiventOperation
#
# ------------------------------------------------------------------------------
# edit operations:
#   CRE) Create
#   MRG) Merge
#   DIS) Dissolve
#   CHB) Change Borders
#   REN) Rename
#   CES) Cease
# ==============================================================================


from django.db import models
from django.utils import timezone
from django.contrib import gis
from djgeojson.fields import *
from django.forms.models import model_to_dict

# ==============================================================================
class EditOperation(models.Model):

  # superordinate: Hivent
  hivent            = models.ForeignKey ('Hivent', related_name='change_hivent')

  # own attribute:
  operation         = models.CharField  (default='XXX', max_length=3)

  # ----------------------------------------------------------------------------
  def __unicode__(self):
    return self.operation

  # ----------------------------------------------------------------------------
  class Meta:
    app_label = 'HistoGlobe_server'
