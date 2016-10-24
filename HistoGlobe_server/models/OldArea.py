# ==============================================================================
# An OldArea is one specific Area + AreaName + AreaTerritory that ends
# due to exactly one HiventOperation.
#
# ------------------------------------------------------------------------------
# OldArea n:1 HiventOperation
# OldArea 1:1 Area
# OldArea 1:1 AreaName
# OldArea 1:1 AreaTerritory
# ==============================================================================


from django.db import models
from django.forms.models import model_to_dict

# ==============================================================================
class OldArea(models.Model):

  # superordinate: HiventOperation
  hivent_operation  = models.ForeignKey ('HiventOperation', related_name='old_hivent_operation', default=0)

  # own attributes
  area              = models.ForeignKey ('Area', related_name='old_area', default=0)
  name              = models.ForeignKey ('AreaName', related_name='old_area_name', default=0)
  territory         = models.ForeignKey ('AreaTerritory', related_name='old_area_territory', default=0)

  # ----------------------------------------------------------------------------
  def __unicode__(self):
    return self.name.short_name

  # ----------------------------------------------------------------------------
  class Meta:
    app_label = 'HistoGlobe_server'