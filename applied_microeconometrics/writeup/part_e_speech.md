# Part (e) — spoken script

Slides 11 and 12, about 3 minutes 45. Slide 11 is the table: orient it, then do
the whole cross-model comparison while the columns are visible. Slide 12 is the
interpretation. To save time, cut the paragraph marked **[optional]**.

---

## Slide 11 — the table: orient

The table reports three estimators of our health expenditure equation, each
shown first without and then with a full set of year dummies. In the pooled OLS
and random effects columns we can include the income group dummies; they drop
out of the fixed effects analysis, because our income group variable is
time-invariant: the World Bank publishes one current classification per economy,
and we apply it to all twelve years. Its within standard deviation is not small,
it is exactly zero. The time-varying variables are log GDP per capita,
government final consumption as a share of GDP, the population share over 65,
log TB incidence, and NCD mortality.

---

---

## Slide 11 — what is robust

Start with what does not change. The coefficient on log GDP per capita lies
between 0.744 and 0.800 in all six columns, is significant at one per cent every
time, and is below one every time. Sign, significance and magnitude are all
stable: whichever estimator we believe, we get the same answer to the question
the paper was written to ask.

Now notice the standard errors on income. Pooled OLS reports 0.062 and fixed effects
reports 0.102, a 65 per cent increase on identical data. This is not a defect of
fixed effects; it is the price of it. Only 0.7 per cent of the variation in log
GDP is within-country, and fixed effects discards the rest. We buy consistency
and we pay in precision.

**[optional]** The income group coefficients are similar in pooled OLS and
random effects, and both are insignificant without year dummies, which is
unsurprising: log GDP already carries the income gradient, so the dummies have
little left to explain. With year dummies, random effects recovers a high income
premium of 0.604, significant at five per cent, while pooled OLS still finds
nothing. We would treat that premium cautiously. It is identified purely from
between-country variation, and the Hausman test tells us that between-country
variation is exactly what we should not trust.

---

---

## Slide 11 — what is fragile

Now the coefficients that do move. Under fixed effects without year dummies, the
share of the population over 65 enters at 0.023 and log TB at minus 0.074, both
significant. Once year dummies are added, ageing falls to essentially zero, TB
to 0.002, and NCD mortality loses significance. The pooled coefficients, by
contrast, move only in the third decimal place.

The explanation is that these three variables move largely in common across
countries. Year dummies remove 54 per cent of the within-country variation in
ageing, 49 per cent in TB and 33 per cent in NCD mortality. Every country is
ageing, and every country's TB incidence is falling, at the same time that
health spending is rising everywhere. Without year effects, fixed effects
credits that common drift to whichever regressor happens to be drifting
alongside it. Once we allow a separate intercept for each year, the drift is
accounted for, and the country-specific deviations that remain bear no
relationship to health spending.

So the honest conclusion is not that ageing does not matter for health
expenditure. It is that twelve years of within-country variation, net of a
common trend, cannot identify it.

Government final consumption is the exception, and the contrast is the
instructive part. It is the only regressor significant in all six models, at
0.014 to 0.020, and it is the only one whose within-country variation is
genuinely country-specific: year dummies remove just three per cent of it.
Fiscal shares move for domestic political reasons, on each country's own
schedule, and that is exactly the kind of variation fixed effects can use.

Finally, on the time-varying variables the random effects estimates lie much
closer to the fixed effects estimates than to pooled OLS: income is 0.746 under
random effects against 0.744 under fixed effects. The estimate of lambda for the
random effects estimation is 0.872.

It is tempting to stop there, but lambda is not the whole explanation.
Quasi-demeaning at 0.872 shrinks the between-country standard deviation of log
GDP from 1.15 to 0.15, and the within standard deviation is only 0.10, so what
random effects actually runs on is still about seventy per cent between-country
variation. What really strips out the between-country identification is the
income group dummies. They explain 87 per cent of the cross-country variation in
log GDP per capita, so once they are in the equation there is very little
between-country income variation left for the elasticity to use. Replace them
with region dummies and random effects returns to 0.818. Fixed effects, by
contrast, gives 0.744 whichever time-invariant control we use, because it
absorbs all of them. That is worth saying plainly: our headline estimate is the
one result in the table that does not depend on this choice.

---

## Slide 12 — the income coefficient

Our preferred estimate, fixed effects with year dummies, is 0.744 with a
standard error of 0.102. Because the equation is log-log, this is the income
elasticity directly: a one per cent rise in real GDP per capita within a country
is associated with a 0.744 per cent rise in real health expenditure per capita.
Testing whether it equals one gives an F statistic of 6.29 with a p-value of
0.013, so we reject at five per cent. Health care behaves as a necessity rather
than a luxury. Growth on its own predicts a *falling* health share of GDP, which
means the rising health shares we all observe have to be explained by something
other than income: technology, relative prices, ageing, or policy.

---

---
