[README (2).md](https://github.com/user-attachments/files/29077608/README.2.md)
# UK E-commerce Retail Analytics

A product/growth analytics project built on the UCI Online Retail II dataset — covering data cleaning, business KPIs, cohort retention, RFM customer segmentation, and churn prediction. Done using Python, PostgreSQL, and Excel, with the core analyses cross-checked across Python and SQL.

## What this project covers

The dataset has about 1 million UK e-commerce transactions from Dec 2009 to Dec 2011. I used it to dig into four questions:

- How is revenue trending, and what's actually driving it (products, countries, seasonality)?
- Are customers coming back after their first purchase?
- Who are the most valuable customers, and who's at risk of leaving?
- Can churn be predicted from past purchase behaviour?

I ran the KPI, cohort, RFM, and churn logic in both Python and PostgreSQL separately, just to get comfortable doing the same analysis in different tools. Final numbers were then pulled into Excel for pivot tables and a small dashboard.

## Tools used

- **Python** (Pandas, NumPy, Matplotlib, Seaborn, Scikit-learn) — cleaning, KPI charts, cohort heatmap, RFM scoring, churn model
- **PostgreSQL** — same cleaning/KPI/cohort/RFM/churn logic written as SQL (CTEs, window functions, joins)
- **Excel** — pivot tables, conditional formatting, and a dashboard with 5 charts

## Repository Structure

- `1_notebooks` — the full Python analysis, done in Google Colab
- `2_sql_queries` — all SQL queries used, written and tested in PostgreSQL
- `3_sql & excel_outputs` — screenshots of query results and the Excel dashboard
- `4_excel` — the Excel workbook with pivot tables and charts
- `5_report` — the final PDF report summarising everything

## Key findings

**Business KPIs**
Total revenue came to about £9.7M over the two years, growing roughly 203% year over year. November is by far the strongest month both years (£1.16M in 2011) — clear holiday-driven seasonality. Top product was the Regency Cakestand 3 Tier (£275K), and EIRE was the biggest market outside the UK (£625K).

**Cohort Retention**
Month-1 retention averages around 5%, which is low and points to a weak onboarding experience. Interestingly, the very first cohort (Dec 2009) still had ~20% of its customers active 24 months later — so there's clearly a loyal core, it's just small.

**RFM Segmentation**
Scored and segmented 5,878 customers into 7 groups. Champions (1,740 customers) spend £8,056 on average — about 46x what the "Lost" segment spends. The segment that needs the most urgent attention is "Cant Lose Them" — 442 customers who used to spend a lot but have gone quiet for 248+ days on average.

**Churn Prediction**
About 51% of customers are inactive past 90 days. A logistic regression model (with scaled features) got to 84.2% accuracy and 0.914 ROC-AUC — recency turned out to be the strongest signal for predicting churn, more than frequency or spend.

## Recommendations

- Build a 60-day onboarding flow to address the Month-1 retention drop
- Run a targeted win-back campaign for the "Cant Lose Them" segment specifically
- Protect the Champions segment — losing even a few of them would hurt revenue disproportionately
- Plan Q4 inventory/marketing earlier given how concentrated revenue is around November
- Use the churn model to flag at-risk customers monthly rather than reacting after they've left

## Full report

The complete writeup with all charts and SQL output screenshots is in [`5_report/UK_Ecommerce_Retail_Analytics_Report.pdf`](./5_report/).

## Author

Sai Surya Vikas Chivukula
BITS Pilani, Hyderabad Campus
[LinkedIn](https://linkedin.com/in/vikas-chivukula-1645682b3) · f20230661@hyderabad.bits-pilani.ac.in
