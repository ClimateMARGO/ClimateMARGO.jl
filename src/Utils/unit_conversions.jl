const year = 365.25 * 24. * 60. * 60.

#  Multiplying by 2.13 converts from parts per million CO2 to Gigatonnes of carbon (https://web.archive.org/web/20170118004650/http://cdiac.ornl.gov/pns/convert.html) and then multiplying by `44/12` gets us back to mass of CO2 (12u + 2*16u = 44u compared to 12u for just elementary carbon). 
GtCO2_to_ppm(GtCO2) = GtCO2 / (2.13 * (44. /12.))
tCO2_to_ppm(tCO2) = GtCO2_to_ppm(tCO2) * 1.e-9

ppm_to_GtCO2(ppm) = ppm * (2.13 * (44. /12.))
ppm_to_tCO2(ppm) = ppm_to_GtCO2(ppm) * 1.e9
