import numpy as np
from sklearn.linear_model import LinearRegression
import coremltools as ct

# Sample training data:
# Features: [wordCount, averageWordLength]
X = np.array([
    [10, 4.5],
    [20, 5.0],
    [30, 5.2],
    [40, 5.5],
    [50, 5.8]
])
# Target: duration (using a simple heuristic: duration = 5 + 0.3 * wordCount)
y = 5 + X[:, 0] * 0.3

# Train a simple linear regression model
model = LinearRegression()
model.fit(X, y)

# Define the input features for the Core ML model.
input_features = [("wordCount", ct.models.datatypes.Double()),
                  ("averageWordLength", ct.models.datatypes.Double())]

# For a regressor, use a string for the output feature name.
output_feature = "duration"

# Convert the scikit-learn model to a Core ML model.
coreml_model = ct.converters.sklearn.convert(model, input_features, output_feature)

# Save the model to a file.
coreml_model.save("QuestionDurationEstimator.mlmodel")

print("Model saved as QuestionDurationEstimator.mlmodel")
