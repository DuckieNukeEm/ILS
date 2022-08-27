import pandas as pd
import datatable as dt
from datatable import f, by
import numpy as np

import re

Dt = dt.fread('~/Data/ILS/2021_ILS.csv')

###
#
# Defining groups
#
###
category = Dt[:,dt.count(), dt.by('Category','Category Name')]

category[:, dt.update(cat_group=dt.ifelse(
								dt.re.match(f['Category Name'],'[a-zA-Z\s]*Rum+[a-zA-Z\s]*'), 'Rum',
								dt.re.match(f['Category Name'],'[a-zA-Z\s]*Vodka+[a-zA-Z\s]*'), 'Vodka',
								dt.re.match(f['Category Name'],'[a-zA-Z\s]*Gin+[a-zA-Z\s]*'), 'Gin',
								dt.re.match(f['Category Name'],'[a-zA-Z0-9_\%\s]*(Tequila)|(Mezcal)+[a-zA-Z\s]*'), 'Tequila',
								dt.re.match(f['Category Name'],'[a-zA-Z\s]*Whisk+[a-zA-Z\s]*'), 'Whiskies',
								dt.re.match(f['Category Name'],'[a-zA-Z\s]*Brand+[a-zA-Z\s]*'), 'Brandies',
								dt.re.match(f['Category Name'],'[a-zA-Z\s\&]*Liqueur+[a-zA-Z\s]*'), 'Liqueurs',
								dt.re.match(f['Category Name'],'Cocktails+[a-zA-Z\s\/]*'), 'Liqueurs',
								dt.re.match(f['Category Name'],'[a-zA-Z\s]*Schnapps+[a-zA-Z\s]*'), 'Schnapps',
								dt.re.match(f['Category Name'],'[\w\s]*Spirit+[\w\s]*'), 'Spirit',
								dt.re.match(f['Category Name'],'.*Special+.*'), 'Speciality',
								dt.re.match(f['Category Name'],'[a-zA-Z\s]*Bourbon+[a-zA-Z\s]*'), 'Bourbon',
								dt.re.match(f['Category Name'],'[a-zA-Z\s]*Scotch+[a-zA-Z\s]*'), 'Scotch',
								dt.re.match(f['Category Name'],'[a-zA-Z\s]*Triple+[a-zA-Z\s]*'), 'Triple Sec',
										   'other'))]

category