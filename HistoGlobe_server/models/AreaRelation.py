# ==============================================================================
# An AreaRelation represents the hierarchical relation between two areas:
# It determines the superordinate Area of the current (subordinate) Area.
# A subordinate Area can also have a certain degree of autonomy.
#
# ------------------------------------------------------------------------------
# AreaRelation n:1 Area
#
# ==============================================================================


from django.db import models
from django.forms.models import model_to_dict
from django.core.validators import MaxValueValidator, MinValueValidator

# ==============================================================================
class AreaRelation(models.Model):

  ## superordinate Area (parent node) in the hierarchy tree of Areas
  superordinate =   models.ForeignKey(
                      'Area', related_name='superordinate_area', default='0')

  ## A subordinate area can have a certain degree of autonomy [0 .. 1[
  ## 0 = no autonomy, normal state / county
  ## 1 = full autonomy = sovereign state
  ## --> (1 is impossible, because then it would not be subordinate)
  autonomy_level =  models.FloatField (default=0.0)


  # ============================================================================
  def __unicode__(self):
    return str(self.id)


  # ============================================================================
  # check if autonomy level is in range [0 .. 1[ and correct to 0.0
  # ============================================================================

  def check_autonomy(self):
	if not ((self.autonomy_level >= 0.0) and (self.autonomy_level < 1.0)):
	  self.autonomy_level = 0.0

  # ============================================================================
  class Meta:
    app_label = 'HistoGlobe_server'
