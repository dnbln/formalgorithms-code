from statistics import NormalDist
import csv

def confidence_interval(data, confidence=0.99):
  dist = NormalDist.from_samples(data)
  z = NormalDist().inv_cdf((1 + confidence) / 2.)
  h = dist.stdev * z / ((len(data) - 1) ** .5)
  return dist.mean - h, dist.mean + h, dist.stdev

IDX_RESULT = 4

def compute_confidence_intervals(ty):
    with open(f'results-{ty}.txt', 'r') as f:
        data = [[float(x) for x in l.strip().split(',')] for l in f.readlines() if l.strip()]

    conf_int_start, conf_int_end, stdev = confidence_interval([x[IDX_RESULT] for x in data])

    print(f"Confidence interval for the mean ({ty}): {conf_int_start:.2f} - {conf_int_end:.2f} (stdev: {stdev:.2f})")

compute_confidence_intervals('tokio')
compute_confidence_intervals('sch')
