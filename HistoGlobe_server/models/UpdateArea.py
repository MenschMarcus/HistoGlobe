# ==============================================================================
# An UpdateArea is one specific Area that changes its name or territory
# due to exactly one HiventOperation.
#
# ------------------------------------------------------------------------------
# UpdateArea 1:1 HiventOperation
# UpdateArea n:1 Area
# UpdateArea n:2 AreaName
# UpdateArea n:2 AreaTerritory
# ==============================================================================


from django.db import models
from django.forms.models import model_to_dict

# ==============================================================================
class UpdateArea(models.Model):

  # superordinate: HiventOperation
  hivent_operation   = models.ForeignKey ('HiventOperation', related_name='update_hivent_operation', default=0)

  # own attributes
  area          = models.ForeignKey ('Area', related_name='update_area', default=0)
  old_name      = models.ForeignKey ('AreaName', related_name='update_area_old_name', null=True)
  new_name      = models.ForeignKey ('AreaName', related_name='update_area_new_name', null=True)
  old_territory = models.ForeignKey ('AreaTerritory', related_name='update_area_old_territory', null=True)
  new_territory = models.ForeignKey ('AreaTerritory', related_name='update_area_new_territory', null=True)

  # ----------------------------------------------------------------------------
  def __unicode__(self):
    return self.area.short_name

  # ----------------------------------------------------------------------------
  class Meta:
    app_label = 'HistoGlobe_server'