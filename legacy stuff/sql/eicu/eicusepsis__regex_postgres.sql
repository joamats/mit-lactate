WITH sepsis_dx AS(
SELECT                                            'cardiovascular|shock / hypotension|sepsis'  as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|sepsis with multi-organ dysfunction' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|sepsis with single organ dysfunction- acute renal failure' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|sepsis with single organ dysfunction- acute respiratory failure' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|sepsis with single organ dysfunction- circulatory system failure' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|sepsis with single organ dysfunction- congestive heart failure' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|sepsis with single organ dysfunction- critical care myopathy' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|sepsis with single organ dysfunction- critical care neuropathy' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|sepsis with single organ dysfunction- metabolic encephalopathy' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|sepsis with single organ dysfunction-acute hepatic failure' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|severe' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|severe|with septic shock' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|sepsis|severe|without septic shock' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|septic shock' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|septic shock|culture negative' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|septic shock|cultures pending' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|septic shock|organism identified' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|septic shock|organism identified|fungal' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|septic shock|organism identified|gram negative organism' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|septic shock|organism identified|gram positive organism' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|septic shock|organism identified|parasitic' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|signs and symptoms of sepsis (SIRS)' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|signs and symptoms of sepsis (SIRS)|due to infectious process with organ dysfunction' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|signs and symptoms of sepsis (SIRS)|due to infectious process with organ dysfunction|non-infectious origin with acute organ dysfunction' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|signs and symptoms of sepsis (SIRS)|due to infectious process without organ dysfunction' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|signs and symptoms of sepsis (SIRS)|due to infectious process without organ dysfunction|systemic inflammatory response syndrome (SIRS) of non-infectious origin witho' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|signs and symptoms of sepsis (SIRS)|due to infectious process without organ dysfunction|unspecified organism' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|signs and symptoms of sepsis (SIRS)|due to non-infectious process with organ dysfunction' as diagnosisstring UNION
SELECT                                            'cardiovascular|shock / hypotension|signs and symptoms of sepsis (SIRS)|due to non-infectious process without organ dysfunction' as diagnosisstring UNION
SELECT                                            'cardiovascular|vascular disorders|arterial thromboembolism|due to sepsis' as diagnosisstring UNION
SELECT                                            'cardiovascular|vascular disorders|peripheral vascular ischemia|due to sepsis' as diagnosisstring UNION
SELECT                                            'endocrine|fluids and electrolytes|hypocalcemia|due to sepsis' as diagnosisstring UNION
SELECT                                            'hematology|coagulation disorders|DIC syndrome|associated with sepsis/septic shock' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|sepsis with multi-organ dysfunction syndrome' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|sepsis with single organ dysfunction- acute renal failure' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|sepsis with single organ dysfunction- acute respiratory failure' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|sepsis with single organ dysfunction- circulatory system failure' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|sepsis with single organ dysfunction- congestive heart failure' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|sepsis with single organ dysfunction- critical care myopathy' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|sepsis with single organ dysfunction- critical care neuropathy' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|sepsis with single organ dysfunction- metabolic encephalopathy' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|sepsis with single organ dysfunction-acute hepatic failure' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|severe' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|severe|septic shock' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|sepsis|severe|without septic shock' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|septic shock' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|septic shock|culture negative' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|septic shock|cultures pending' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|septic shock|fungal' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|septic shock|gram negative organism' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|septic shock|gram positive organism' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|septic shock|organism identified' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|septic shock|parasitic' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|signs and symptoms of sepsis (SIRS)' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|signs and symptoms of sepsis (SIRS)|due to infectious process with organ dysfunction' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|signs and symptoms of sepsis (SIRS)|due to infectious process without organ dysfunction' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|signs and symptoms of sepsis (SIRS)|due to non-infectious process with organ dysfunction' as diagnosisstring UNION
SELECT                                            'infectious diseases|systemic/other infections|signs and symptoms of sepsis (SIRS)|due to non-infectious process without organ dysfunction' as diagnosisstring UNION
SELECT                                            'pulmonary|respiratory failure|acute lung injury|non-pulmonary etiology|sepsis' as diagnosisstring UNION
SELECT                                            'pulmonary|respiratory failure|ARDS|non-pulmonary etiology|sepsis' as diagnosisstring UNION
SELECT                                            'renal|disorder of kidney|acute renal failure|due to sepsis' as diagnosisstring UNION
SELECT                                            'renal|electrolyte imbalance|hypocalcemia|due to sepsis' as diagnosistring
                                                                                                                                                                                )
                                                                                                                                                                               
select * from sepsis_dx s INNER JOIN diagnosis d ON s.diagnosisstring=d.diagnosisstring;
