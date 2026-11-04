// Addiction is dose-dependent. Each reagent's addiction_threshold is the amount of a "normal dose".
// Every unit metabolised adds (1 / addiction_threshold) to a hidden dependence value held by the holder,
// which fades over time. Crossing ADDICTION_LIMIT hooks the user, so a single dose never does.
#define ADDICTION_LIMIT 4 // dependence needed to become addicted, roughly three normal doses
#define ADDICTION_WARN_FRACTION 0.5 // fraction of the limit at which the user is warned
#define ADDICTION_DECAY 0.002 // dependence lost per life tick, about a dose every half hour
