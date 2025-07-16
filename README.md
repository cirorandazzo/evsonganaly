# evsonganaly

Audio segmentation & labeling software developed in Brainard Lab at UCSF, initially by Evren Tumer. The first work published with data collected using EvTAF and evsonganaly is in this paper:  
> Tumer, Evren C., and Michael S. Brainard.  
> "Performance variability enables adaptive plasticity of 'crystallized' adult birdsong."  
> Nature 450.7173 (2007): 1240.  
> <https://www.nature.com/articles/nature06390>  

## Brief user guide of keypresses

- Label Mode (`switch newlabelfix`)
    - Esc: quit label mode
    - Backspace/left arrow: select previous label
    - Forward arrow*: next label
    - Up arrow*: next window
    - Down arrow*: previous window
- Edit Mode: Window selection (`switch btnval`)
    - Left mouse: move left window bound
    - Right mouse: move right window bound
    - Center mouse: snap window to note clicked on
- Edit Mode: Post-selection (`switch editfuncfix`)
    - Esc: quit edit mode & do nothing
    - Enter: creates new note at selection. Does not affect notes in window
    - M: creates new note at selection. Merges all notes wholly contained in window (does not affect notes partially in window).
    - D: Deletes any wholly-contained notes AND clips any partially-contained notes.
    - C: Deletes everything except currently selected notes.
    - O: Overlap mode. See image below.
    - Space: plays selected audio

(*) indicates that I haven't confirmed this is the actual function, but it seems like what the code is doing

Overlap mode:
<img width="1202" height="795" alt="overlap_mode" src="https://github.com/user-attachments/assets/09fe67b9-1a68-46e5-96a7-9f5a93a30017" />
