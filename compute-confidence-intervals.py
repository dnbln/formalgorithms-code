from math import sqrt
from statistics import NormalDist
from scipy import stats

CONNECTIONS = 1000
ITERATIONS = 10

def cohens_d(mean_x, mean_y, sigma_x, sigma_y) -> float:
    """
    Cohen's d for two independent samples.
      x, y      – 1-D NumPy arrays of the two groups
    """
    pooled_sd = sqrt((sigma_x ** 2 + sigma_y ** 2) / 2)  # Glass–Hedges assumes equal n
    return (mean_x - mean_y) / pooled_sd

def confidence_interval(data, confidence=0.95):
  dist = NormalDist.from_samples(data)
  z = NormalDist().inv_cdf((1 + confidence) / 2.)
  h = dist.stdev * z / ((len(data) - 1) ** .5)
  return dist.mean - h, dist.mean + h, dist.mean, dist.stdev

IDX_RESULT = 4

def compute_confidence_intervals(ty):
    with open(f'results-{ty}.txt', 'r') as f:
        data = [[float(x) for x in l.strip().split(',')] for l in f.readlines() if l.strip()]

    used_data = [x for x in data if x[0] == CONNECTIONS and x[1] == ITERATIONS]
    conf_int_start, conf_int_end, mean, stdev = confidence_interval([x[IDX_RESULT] for x in used_data])

    print(f"Confidence interval for the mean ({ty}, samples: {len(used_data)}): {mean:.2f} {conf_int_start:.2f} - {conf_int_end:.2f} (stdev: {stdev:.2f})")

    return conf_int_start, conf_int_end, mean, stdev, len(used_data)

_, _, meantokio, stdevtokio, ntokio = compute_confidence_intervals('tokio')
_, _, meansch, stdevsch, nsch = compute_confidence_intervals('sch')

print(f"Cohen's d: {cohens_d(meantokio, meansch, stdevtokio, stdevsch):.2f}")

t_sc, p_sc = stats.ttest_ind_from_stats(meantokio, stdevtokio, ntokio,
                                        meansch,   stdevsch,   nsch,
                                        equal_var=False)

print(f"T-test: t-statistic = {t_sc:.2f}, p-value = {p_sc}")

