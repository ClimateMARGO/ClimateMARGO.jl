const year = 365.25 * 24. * 60. * 60.

GtCO2_to_ppm(GtCO2) = GtCO2 / (2.13 * (44. /12.))
tCO2_to_ppm(tCO2) = GtCO2_to_ppm(tCO2) * 1.e-9

ppm_to_GtCO2(ppm) = ppm * (2.13 * (44. /12.))
ppm_to_tCO2(ppm) = ppm_to_GtCO2(ppm) * 1.e9