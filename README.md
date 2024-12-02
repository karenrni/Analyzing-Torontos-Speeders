# Tracking Speed Demons: Exploring Excessive Speeding Near Traffic Cameras in Toronto School Zones

## Overview

This project analyzes extreme speeding patterns around schools and traffic cameras in Toronto using data from the [School Safety Zone Watch Your Speed Program Data](https://open.toronto.ca/dataset/school-safety-zone-watch-your-speed-program-locations/) and [Traffic Camera dataset](https://open.toronto.ca/dataset/traffic-cameras/). By visualizing speeding hotspots and identifying trends, this study aims to highlight areas with frequent violations and discuss the implications for road safety and enforcement strategies. The project also explores whether traffic calming measures or enforcement zones effectively reduce extreme speeding incidents around school zones.


## File Structure

The repository is organized as follows:

- `data/raw_data`: contains the raw data as obtained from OpenDataToronto, including the simulated data
- `data/analysis_data`: Contains the cleaned data used for analysis and modeling.
- `models`: Contains the fitted models, including saved models in `.rds` format.
- `other`: Documents any assistance from ChatGPT-4o and preliminary sketches.
- `paper`: contains the files used to generate the paper, including the Quarto document and reference bibliography file, as well as the PDF of the paper.
- `scripts`: Contains the R scripts used to simulate, download, clean, test, analyze and model the data.

## Statement on LLM usage

Aspects of the code were written with the help of the ChatGPT-4o, including graphing and some conceptual assistance. It is available in `other/llm_usage`.

## Data Reproducibility

Due to a known issue of tibble_error_incompatible_size in the column lengths in the topics and formats fields from the opendatatoronto package, the dataset could not be directly downloaded via the API during the project timeline. Alternatively, downloads are available directly from OpenDataToronto's website link.