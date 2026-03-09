# -------------------------------
# MD Analysis Plots Date: 2026-03-08
# -------------------------------

library(ggplot2)

# Output directory
outdir <- "~/md_plots"
if(!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)

# Function to read GROMACS .xvg files
read_xvg <- function(file) {
  lines <- readLines(file)
  lines <- lines[!grepl("^@|^#", lines)]  # remove comments
  data <- read.table(text = lines, fill = TRUE)
  colnames(data) <- c("Time", "Value")
  return(data)
}

# General plotting function
plot_xvg <- function(file, ylab, title, outname, color="steelblue") {
  df <- read_xvg(file)
  p <- ggplot(df, aes(x=Time, y=Value)) +
    geom_line(color=color, linewidth=0.8) +
    xlab("Time (ps)") +
    ylab(ylab) +
    ggtitle(title) +
    theme_bw(base_size=12)
  ggsave(filename=file.path(outdir, outname), plot=p, width=6, height=4, dpi=300)
  cat("Saved:", outname, "\n")
}

# ===== INDIVIDUAL PLOTS =====
plot_xvg("rmsd.xvg", "RMSD (nm)", "Backbone RMSD", "RMSD.png", "darkblue")
plot_xvg("lmsd_JWH.xvg", "LMSD (nm)", "Ligand MSD", "LMSD.png", "red")
plot_xvg("rmsf.xvg", "RMSF (nm)", "Residue-wise Fluctuation", "RMSF.png", "darkgreen")
plot_xvg("rg.xvg", "Radius of Gyration (nm)", "Radius of Gyration", "Rg.png", "purple")
plot_xvg("hbonds.xvg", "Number of H-bonds", "Protein H-bonds", "Hbonds.png", "forestgreen")
plot_xvg("dist_ligand.xvg", "Distance (nm)", "Ligand-Protein Distance", "Distance.png", "firebrick")
plot_xvg("mindist_JWH.xvg", "Minimum Distance (nm)", "Minimum Ligand Distance", "MinDistance.png", "orange")
plot_xvg("temperature.xvg", "Temperature (K)", "Temperature", "Temperature.png", "goldenrod")
plot_xvg("gyrate_nopbc.xvg", "Gyration (nm)", "Radius of Gyration (No PBC)", "Gyrate.png", "slateblue")
plot_xvg("sasa.xvg", "SASA (nm^2)", "Solvent Accessible Surface Area", "SASA.png", "darkcyan")
plot_xvg("density.xvg", "Density (kg/m^3)", "System Density", "Density.png", "darkorange")
plot_xvg("potential.xvg", "Potential Energy (kJ/mol)", "Potential Energy", "Potential.png", "darkred")

# ===== RMSD vs LMSD Overlay =====
df_rmsd <- read_xvg("rmsd.xvg")
df_lmsd <- read_xvg("lmsd_JWH.xvg")

# Align common time window
tmin <- max(min(df_rmsd$Time), min(df_lmsd$Time))
tmax <- min(max(df_rmsd$Time), max(df_lmsd$Time))
df_rmsd <- df_rmsd[df_rmsd$Time >= tmin & df_rmsd$Time <= tmax, ]
df_lmsd <- df_lmsd[df_lmsd$Time >= tmin & df_lmsd$Time <= tmax, ]

# Add Type column for ggplot legend
df_rmsd$Type <- "RMSD"
df_lmsd$Type <- "LMSD"
df_combined <- rbind(df_rmsd, df_lmsd)

p <- ggplot(df_combined, aes(x=Time, y=Value, color=Type)) +
  geom_line(linewidth=0.8) +
  scale_color_manual(values=c("RMSD"="darkblue", "LMSD"="red")) +
  xlab("Time (ps)") +
  ylab("Deviation (nm)") +
  ggtitle("Backbone RMSD vs Ligand MSD") +
  theme_bw(base_size=12) +
  theme(legend.position="top")

ggsave(file.path(outdir, "RMSD_vs_LMSD.png"), plot=p, width=6, height=4, dpi=300)
cat("Saved: RMSD_vs_LMSD.png\n")

# ===== Distance vs H-bonds Overlay =====
df_dist <- read_xvg("dist_ligand.xvg")
df_hb <- read_xvg("hbonds_JWH.xvg")

# Align common time window
tmin <- max(min(df_dist$Time), min(df_hb$Time))
tmax <- min(max(df_dist$Time), max(df_hb$Time))
df_dist <- df_dist[df_dist$Time >= tmin & df_dist$Time <= tmax, ]
df_hb <- df_hb[df_hb$Time >= tmin & df_hb$Time <= tmax, ]

# Scale H-bonds to match distance for overlay
p <- ggplot() +
  geom_line(data=df_dist, aes(Time, Value), color="firebrick", linewidth=0.8) +
  geom_line(data=df_hb, aes(Time, Value * max(df_dist$Value)/max(df_hb$Value)), color="steelblue", linewidth=0.8) +
  scale_y_continuous(
    name = "Ligand Distance (nm)",
    sec.axis = sec_axis(~ . * max(df_hb$Value)/max(df_dist$Value), name="Number of H-bonds")
  ) +
  xlab("Time (ps)") +
  ggtitle("Ligand Distance vs Hydrogen Bonds") +
  theme_bw(base_size=12) +
  theme(legend.position="top")

ggsave(file.path(outdir, "Distance_vs_Hbonds.png"), plot=p, width=7, height=4, dpi=300)
cat("Saved: Distance_vs_Hbonds.png\n")

cat("All plots generated successfully in", outdir, "\n")
