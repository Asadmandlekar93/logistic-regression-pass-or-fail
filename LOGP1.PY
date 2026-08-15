import pandas as pd
from sklearn.linear_model import LogisticRegression

# Dataset
data = {
    "Hours": [1, 2, 3, 4, 5, 6],
    "Pass": [0, 0, 0, 1, 1, 1]
}

df = pd.DataFrame(data)

X = df[["Hours"]]
y = df["Pass"]

# Create model
model = LogisticRegression()

# Train model
model.fit(X, y)

# Predict
prediction = model.predict([[4.5]])

print("Prediction:", prediction)

if prediction[0] == 1:
    print("Student will Pass")
else:
    print("Student will Fail")