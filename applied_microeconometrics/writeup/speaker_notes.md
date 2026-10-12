# Speaker notes: Determinants of Health Expenditure (Group 3)

13 slides, about **12 minutes 35** of talking. Slide numbers match the deck.

| Part | Slides | Budget |
|---|---|---|
| Title | 1 | 0:30 |
| (a) Reference paper | 2 | 0:45 |
| (b) How this differs | 3 | 1:00 |
| (c) Data and descriptives | 4 to 8 | 3:20 |
| (d) Tests and lambda | 9 | 1:45 |
| **(e) Results** | **10 to 11** | **3:45** |
| (f) Conclusions and next steps | 12 | 1:30 |

**Three things live only in what you say, not on a slide:**

1. **Which model is preferred.** Say it at the end of slide 9.
2. **How the coefficients vary across the models.** Part (e) asks for this in writing — significance, sign, magnitude. Delivered over the table on slide 10, whose note is scripted in four passes.
3. **Why FE cannot identify income group.** Now a spoken point on slide 8, and again on slide 12.

If you run long, cut the region table on slide 4 and slide 7 (disease burden). Do not cut anything in part (e).

---

## Slide 1. Title slide

*Budget: 0:30*

Thirty seconds. Open with the question, not the paper.

"The question we answer is one of the oldest in health economics. When a country
gets richer, does it spend proportionately more on health? If the income
elasticity is above one, health care is a luxury good and the health share of
GDP rises mechanically with development. If it is below one, health care is a
necessity, and rising health shares need a different explanation."

"We re-estimate this on 145 countries, 2010 to 2021, a window that includes
COVID. Our headline number is 0.744."

Do not read out the names or the roll numbers.

---

## Slide 2. (a) Xu, Saksena and Holly (2011)

*Budget: 0:45*

Forty-five seconds. Three things only.

1. The motivation is coverage. Everything known about the income elasticity came
   from rich countries, and the policy question is about poor ones.
2. Their answer is below one. Health care is a necessity.
3. Flag the TB limitation now, because it sets up the next slide. Say it in
   their words: this was a constraint, not a choice. NCD time series did not
   exist when they wrote.

If asked why they also run Blundell and Bond: GDP and health spending are
jointly determined, so they instrument income with its own lags. We do not,
because the assignment fixes the estimator set to pooled, FE and RE.

---

## Slide 3. (b) How this study differs

*Budget: 1:00*

One minute. Do not read the table. Let it sit and speak to the two bullets.

The line that matters: "their conclusion was established on a period of
uninterrupted growth. Ours includes 2020. That is the real test."

Be ready for a challenge on fiscal capacity, but do not volunteer it. Answer if
asked: their series, Expense as a per cent of GDP, covers only 76.5 per cent of
our country-years and just 91 of 162 candidate countries across all twelve
years. Government final consumption is narrower, it excludes transfers,
subsidies, interest and capital formation, so it is a lower bound on fiscal
space. We took the complete series because a balanced panel is required for the
tests in part (d) to compare all three models on an identical sample.

---

## Slide 4. (c) The panel

*Budget: 0:30*

Thirty seconds. Two points, then move.

"Balanced. That matters because all three estimators must run on an identical
sample for the tests in part (d) to be valid comparisons."

"Log-log in expenditure and income, so beta one is the elasticity itself, and
research question one reduces to testing beta one equals one. Percentage
variables, government consumption, the over-65 share and NCD mortality, enter in
levels, so their coefficients read as the effect of a one percentage point
change."

Do not walk through the region table. It is there to show the coverage is not
OECD-only, which was the whole motivation of the reference paper.

---

## Slide 5. (c) Expenditure against income

*Budget: 0:40*

Forty seconds. This slide does one job: it sets up fixed effects visually.

Point at the right-hand side of the cloud. "Two countries here have the same GDP
per capita and spend a factor of two apart on health. Whatever explains that is
not in our regressor list. It is health system design, relative medical prices,
institutional quality. It is time-invariant and it is correlated with income.
That is exactly what u-i is, and it is why we end up rejecting pooled OLS."

---

## Slide 6. (c) The health share of GDP over time

*Budget: 0:40*

Forty seconds. This is the slide that justifies time dummies.

"Two readings. First, the pre-2019 flatness is Xu et al.'s result reappearing on
a completely different window and a different accounting basis. That is
reassuring for replication."

"Second, 2020 is a level shift that hits every income group at once. It is a
common time effect. If we leave year dummies out, that shock loads onto whatever
regressor happens to be trending, and in part (e) we will see it do exactly
that."

Numbers if asked: high income runs 7.4 to 7.9 per cent through 2019, the other
three groups 4.2 to 6.5.

---

## Slide 7. (c) Disease burden across the income gradient

*Budget: 0:30*

Thirty seconds. This slide justifies our one substantive addition to the paper.

Say the log-scale caveat before anyone raises it: "the left panel is
logarithmic, so its gradient is much steeper than it looks sitting next to the
right panel."

The punchline: "TB alone is a good proxy for disease burden in poor countries
and a bad one in rich countries. Since income is our regressor of interest, a
proxy whose quality varies systematically with income is the worst kind of
measurement error to have."

---

## Slide 8. (c) Summary statistics: **xtsum**

*Budget: 1:00*

One minute. This is the raw output AND the interpretation, since the ratio
slide is gone. Read it, do not just show it.

Say what the three rows are, once: "overall is every country-year pooled
together. Between is the 145 country averages. Within is how much one country
moves around its own average."

Then the number that matters, pointing at log GDP: "between standard deviation
1.153, within standard deviation 0.096. A ratio of twelve. Two randomly chosen
countries differ in income about twelve times more than one country differs
between two randomly chosen years. In variance terms only 0.7 per cent of the
variation in income is within-country."

Then the payoff, said explicitly so part (e) is not a surprise:
"Fixed effects throws the between variation away, so for income it works with
0.7 per cent of the variance. Expect a much larger FE standard error on income,
and expect the slow-moving variables, ageing and NCD mortality, to fall apart
under FE once year dummies take out the common trend. Both things happen."

The exception, worth naming: "government final consumption is the one regressor
with real within-country movement, 12 per cent of its variance. It is the only
one significant in every column of the next table, and that is not a
coincidence."

Income group is not in this table because it has nothing to decompose: its
within standard deviation is exactly zero, so fixed effects cannot identify it
at all. Say that when the FE column comes up blank on the results slide. Be
precise about why it is zero: the World Bank reclassifies economies every year
and several countries did move group between 2010 and 2021, but the API serves
one current classification per country with no year dimension, and we apply it
to all twelve years. Time-invariant by construction, not because the world stood
still. If challenged: the assignment requires a time-invariant regressor, the
historical OGHIST series is not on the API, and the cost is that a country
reclassified mid-window carries its end-of-period status throughout.

Two facts held in reserve:
- The negative within minimum for government consumption is not a negative
  share. xtsum adds the grand mean back, so a within value of minus 17.7 means a
  country running 34 points below its own average. Both extremes are Timor-Leste,
  at 103 per cent of GDP in 2010 and 28 per cent by 2021.
- Bangladesh has zero within variation in TB, a constant 221 per 100,000 for all
  twelve years, so it contributes nothing to the FE TB coefficient.

---

## Slide 9. (d) Tests of hypotheses, and the estimated lambda

*Budget: 1:45*

Ninety seconds. Take the three tests fast, then spend the time on lambda.

(i) "F test on the joint significance of the 144 country effects, read off the
foot of xtreg fe. Rejects. Country effects exist."

(ii) "Breusch and Pagan LM. Null is that the variance of u-i is zero. Rejects.
Same verdict from the random effects side. Note the distribution is chi-bar
squared, a fifty-fifty mixture, because the null puts a variance on the boundary
of the parameter space."

(iii) "Hausman. Null is that u-i is uncorrelated with the regressors, so RE is
consistent and efficient. Rejects at 0.1 per cent."

Then lambda, slowly, because this is what the question specifically asks for:

"Lambda is the quasi-demeaning weight. Random effects does not use raw data and
it does not use fully demeaned data. It subtracts lambda times the country mean.
At zero you get pooled OLS, at one you get fixed effects. Ours is 0.872."

"Lambda is high because rho is 0.834: five-sixths of the residual variance is
the country effect. With T equal to twelve and country effects that strong, GLS
leans hard on within variation."

Do NOT say a high lambda means RE is nearly FE. Quasi-demeaning at 0.872 shrinks
the between-country standard deviation of log GDP from 1.153 to 0.147, but the
within standard deviation is only 0.096. So the regressor RE actually runs on is
still 70 per cent between-country variation. Lambda describes the
transformation, not where the estimate lands.

Then give the verdict out loud, since no slide now carries it:
"All three reject. Pooled OLS is out on two independent tests, and Hausman puts
random effects out as well. The preferred specification is fixed effects with
time dummies."

Add the honesty line, which is the one that earns marks: "the Hausman test
rejects on the joint coefficient vector. Our parameter of interest moves only
from 0.746 under RE to 0.744 under FE, against a standard error near 0.10. So
the model choice is defensible, but it is not what drives our headline number."

Two honest caveats, if asked:
- All three tests use conventional standard errors, because none of them is
  reported under vce(cluster). Hausman in particular needs RE to be efficient
  under the null, which clustering breaks.
- Income group is dropped from the Hausman test: FE cannot identify a
  time-invariant regressor and the test needs a shared coefficient vector. With
  time dummies Stata reports the differenced covariance matrix is rank 5 against
  16 coefficients and not positive definite, so we treat 78.04 as corroborating
  and lean on the clean 20.84. Both reject.

Held in reserve, an argument that needs no test: 145 countries with complete
data are closer to the population than to a random draw from it. Random effects
treats each country effect as a draw from a distribution; we are not sampling
countries, we have nearly all of them. Each effect is better treated as a
separate intercept, which is mechanically what FE does. Wooldridge makes this
point for policy analysis on aggregated data, page 493. We still report RE,
because FE cannot identify income group at all.

---

## Slide 10. (e) Pooled OLS, fixed effects and random effects

*Budget: 2:15*

Two and a quarter minutes. This slide now carries the whole cross-model
comparison, so do not rush it. Orient first, then robust, then fragile.

ORIENT (20 seconds). "Six columns. Three estimators, first without time dummies
and then with. Cluster-robust standard errors by country throughout. Column
five, fixed effects with time dummies, is our preferred specification, and 0.744
is the number the whole study turns on."

Two structural features, then stop describing:
- The FE columns are blank for income group. Fixed effects absorbs anything
  time-invariant, and our income classification has a within standard deviation
  of exactly zero. Not a missing result, the estimator working as designed.
- Year dummies are jointly significant in all three models: F of 4.29 pooled,
  6.51 under FE, chi-squared of 58.56 under RE. Common time effects belong in
  the specification, which vindicates the 2020 break on the trend figure.

WHAT IS ROBUST (45 seconds). Point along the top row.
"Income. Six columns, six times significant at one per cent, six times below
one, range 0.744 to 0.800. Sign, significance and magnitude are all stable.
Whatever you believe about country effects, you get the same answer."

Then the price of FE, pointing at the standard errors: "0.062 pooled against
0.102 under FE, a 65 per cent increase on identical data. Fixed effects is not
free. It buys consistency by discarding 99 per cent of the variation in the
regressor, and you pay in precision."

Then government consumption: "the only regressor significant in every single
column, 0.014 to 0.020, and not a coincidence: it is the only one with real
within-country variation, twelve per cent. A one percentage point rise in the
government consumption share goes with 1.4 to 2.0 per cent higher health
spending per capita. Fiscal capacity is the robust time-varying driver here."

WHAT IS FRAGILE (60 seconds). Point down the FE columns.
"Now the three that move. Without year dummies, ageing enters at 0.023 and log
TB at minus 0.074, both significant. Add year dummies and ageing goes to
essentially zero, TB to 0.002, NCD loses significance. Pooled, by contrast,
moves in the third decimal."

State the mechanism carefully, because the obvious explanation is wrong: "it is
not that no variation is left. Year dummies remove about half the within-country
variation in ageing and TB, and a third in NCD mortality. Two thirds survives.
What year dummies take is the part every country shares. Every country is
ageing, every country's TB is falling, at the same time that health spending is
rising everywhere. Without year effects, fixed effects credits that common drift
to whichever regressor drifts alongside it."

The contrast that proves it: "government consumption loses only three per cent
of its within variation to year dummies, because fiscal shares move on each
country's own political schedule. That is the one regressor whose variation is
genuinely country-specific, and it is the one that survives everywhere."

So the honest conclusion is not that ageing does not matter for health
expenditure. It is that twelve years of within-country variation, net of a
common trend, cannot identify it.

RE VERSUS FE (20 seconds). "Random effects sits at 0.746, right beside fixed
effects at 0.744. Lambda is 0.872, but that is not the reason: after
quasi-demeaning the regressor is still 70 per cent between-country. What strips
the between identification is the income dummies, which explain 87 per cent of
the cross-country variation in log GDP. Replace them with region dummies and RE
returns to 0.818, while FE stays at 0.744 whatever control we use."

Income group is the one real disagreement: FE absorbs it, pooled finds it
insignificant because log GDP already carries the income gradient, and RE
recovers a high income premium of 0.604. Treat that premium with caution: it is
identified purely off between-country variation, which Hausman tells us not to
trust, and the classification itself is measured from 2025 GNI.

If anyone asks about the 0.953 R-squared: not comparable with the 0.445. The
first is overall fit dominated by between-country variation, the second is
within-country fit. Different quantities.

---

## Slide 11. (e) Interpreting the income coefficient

*Budget: 1:30*

Ninety seconds. This is the core of the talk. Slow down here.

Give the interpretation in one clean sentence and stress the word "within":
"this is not rich countries spend more than poor countries. It is the same
country spending more as it grows. That distinction is the entire reason we are
using panel data rather than a cross-section."

Then the test. "Because it is log-log the coefficient is the elasticity, so the
luxury-versus-necessity question is just a test of whether it equals one. F of
6.29, p of 0.013. Rejected. Below one. Necessity."

Then the economics, which is what earns the marks: "the policy implication is
that you cannot explain rising health shares of GDP by saying countries got
richer. Growth alone predicts a falling share. So the rise has to come from
somewhere else: medical technology, relative price growth in a labour-intensive
sector, ageing, or deliberate policy expansion."

Close on replication: "we changed the decade, the accounting standard, the
fiscal variable and the age cutoff, we added NCD burden, and we included a
pandemic. The elasticity barely moved. That is a genuinely robust finding."

Two answers to hold ready:
- Does 0.744 differ from their 0.75? No. It is within a tenth of a standard
  error. We are not claiming a lower elasticity, we are claiming the same one.
- Is it causal? No, and say so before being asked. It is a conditional
  within-country association. Health spending is a component of GDP, so income
  is not strictly exogenous. That is the first item on the extensions slide.

---

## Slide 12. (f) Conclusions, and what we would do next

*Budget: 1:30*

Ninety seconds for the whole slide. Findings fast, extensions slower.

FINDINGS (35 seconds). Three points, roughly one breath each. Do not elaborate;
the elaboration already happened in part (e).

The sentence to land on is the second: "growth alone predicts a falling health
share." It is counter-intuitive, it is the paper's actual contribution, and it
is what an audience remembers.

EXTENSIONS (55 seconds). This is where an examiner will probe. Lead with the
first, because it is the real weakness and volunteering it beats being caught.

Say it in plain words, no jargon needed:
"Our number says health spending and income move together within a country. It
does not prove that growth caused the spending, and the reason is almost silly:
health spending is counted inside GDP. So the thing we are explaining sits
inside the thing we are explaining it with. The standard fix is to use the
country's income from earlier years, because the past cannot be caused by today.
That is what Xu et al. do. We could not, because the assignment fixes us to
pooled, FE and RE."

On the second, own the income group limitation rather than waiting to be asked:
"the World Bank reclassifies countries every year, but the API gives one current
classification per country with no year dimension, so ours is time-invariant by
construction. A country reclassified mid-window carries its end-of-period status
throughout. It matters more than it looks, because the classification explains
87 per cent of the cross-country variation in log GDP."

Do not go deeper unless they push. If they do, the names are:
- Blundell-Bond for point one.
- OGHIST, the World Bank's historical classification spreadsheet, for point two.
- Driscoll-Kraay for the 2020 standard errors and Mundlak or Hausman-Taylor for
  keeping income group, both in point three. A Mundlak correction in practice is
  just adding each country's average income as an extra regressor in the RE
  model: you get the FE answer on the time-varying variables and still get a
  coefficient on income group.

Stop here. Thank them and take questions.

---

## Slide 13. Thank you

*Budget: Q&A*

Leave this up through the Q and A.

Likely questions, with short answers:

Q. Why not cluster-robust standard errors for the tests in part (d)?
A. Those tests rely on the classical variance structure. Hausman in particular
   needs RE to be efficient under the null, which clustering breaks. We cluster
   for the coefficient tables, which is where it matters.

Q. Why is lambda so high?
A. T is twelve and rho is 0.834. Five-sixths of the residual variance is the
   country effect, so GLS weights within variation heavily.

Q. Why include the income dummies at all, if FE cannot identify them?
A. Two reasons. They are the assignment's required time-invariant regressor, and
   they are identified in pooled OLS and RE, which is where the high income
   premium of 0.604 comes from. FE absorbing them is itself a result worth
   showing.

Q. Did no country really change income group in twelve years?
A. Countries did; our variable does not. The World Bank API serves one current
   classification per economy with no year dimension, so we apply it to all
   twelve years. The historical series is the OGHIST spreadsheet, which the API
   does not expose. The cost is that a country reclassified mid-window carries
   its end-of-period status throughout.

Q. Why is the TB coefficient negative?
A. Not a demand response. Conditional on income, TB incidence marks weak health
   systems and residual underdevelopment.

Q. An R-squared of 0.953 for pooled OLS?
A. Overall fit, dominated by between-country variation. Not comparable with the
   0.445 within figure for FE.

Q. Why a balanced panel? Are you not throwing away countries?
A. Yes, and deliberately. The three tests in part (d) are only valid comparisons
   if all three estimators run on an identical sample.

Q. Why 2010 as the start?
A. SHA 2011 coverage. Earlier years are on the old accounting basis and are not
   comparable. The window ends in 2021 because that is the last year NCD
   mortality is published.

---
