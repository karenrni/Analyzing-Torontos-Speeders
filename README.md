# Exploring Speeding Near Traffic Cameras in Toronto School Zones

## Overview

This project analyzes speeding patterns around schools and traffic cameras in Toronto using data from the [School Safety Zone Watch Your Speed Program data](https://open.toronto.ca/dataset/school-safety-zone-watch-your-speed-program-locations/), [Watch Your Speed Detailed Counts data](https://open.toronto.ca/dataset/school-safety-zone-watch-your-speed-program-detailed-speed-counts/) and [Traffic Camera dataset](https://open.toronto.ca/dataset/traffic-cameras/). By visualizing speeding hotspots and identifying trends, this study aims to highlight areas with frequent violations and discuss the implications for road safety and enforcement strategies. The project also explores whether traffic calming measures effectively reduce extreme speeding incidents around school zones.


## File Structure

The repository is organized as follows:

- `data/raw_data`: contains the raw data as obtained from OpenDataToronto, including the simulated data
- `data/analysis_data`: Contains the cleaned data used for analysis and modeling.
- `models`: Contains the fitted models, including saved models in `.rds` format.
- `other`: Documents any assistance from ChatGPT-4o, datasheet, and preliminary sketches.
- `paper`: contains the files used to generate the paper, including the Quarto document and reference bibliography file, as well as the PDF of the paper.
- `scripts`: Contains the R scripts used to simulate, download, clean, test, analyze and model the data.

## Interactive Map of Speeding Events Near Schools
Please see [here](https://karenrni.github.io/leaflet-web-map/)
## Data Reproducibility

Due to a known issue of tibble_error_incompatible_size in the column lengths in the topics and formats fields from the opendatatoronto package, the dataset could not be directly downloaded via the API during the project timeline. Alternatively, downloads are available directly from OpenDataToronto's website link.


## Handling Large Speed Count Files
The **School Safety Zone: Watch Your Speed Program Detailed Speed Counts** dataset contains a large number of CSV files, which may be too large to process and store directly in this repository. Instead:

1. **Download Instructions**:
   - The dataset can be downloaded manually from the [Open Toronto Data Portal](https://open.toronto.ca/dataset/school-safety-zone-watch-your-speed-program-detailed-speed-counts/).
   - Alternatively, use the code provided in the `01_download_data.R` script to automate the download process.

2. **Combining Files**:
   - The script in `01_download_data.R` includes the logic to unzip and combine the files into a single dataframe for analysis.
   - The step `## Step 3: Combine CSV Files ##` includes the necessary code for combining the files using `map_dfr()`.

3. **Repository Constraints**:
   - Due to file size constraints, the combined dataset and detailed speed counts zip file are not stored in this repository under data/raw_data. Users must generate it locally by running the provided script.
   
## Statement on LLM usage

Aspects of the code were written with the help of the ChatGPT-4o, including graphing, debugging, and some conceptual assistance. It is available in `other/llm_usage`.

