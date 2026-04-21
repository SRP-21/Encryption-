"""
ID3 Decision Tree — built from scratch (no sklearn for the tree itself)
Dataset: dataset_clean.csv  (network-packet security classification)
Target : security  (LOW | MEDIUM | HIGH)
Features: packet_type, size, frequency, trust, anomaly  (all categorical)
"""

import math
import pandas as pd
from collections import Counter

# ──────────────────────────────────────────────
# 1. CORE ID3 MATHS
# ──────────────────────────────────────────────

def entropy(labels):
    """Shannon entropy H(S) = -Σ p_i · log2(p_i)"""
    n = len(labels)
    if n == 0:
        return 0.0
    counts = Counter(labels)
    return -sum((c / n) * math.log2(c / n) for c in counts.values() if c > 0)


def information_gain(df, feature, target):
    """
    IG(S, A) = H(S) - Σ (|S_v| / |S|) · H(S_v)
    where S_v is the subset where feature A == v.
    """
    total_entropy = entropy(df[target])
    n = len(df)
    weighted_entropy = 0.0
    for value, subset in df.groupby(feature):
        weighted_entropy += (len(subset) / n) * entropy(subset[target])
    return total_entropy - weighted_entropy


def best_feature(df, features, target):
    """Return the feature with the highest Information Gain."""
    gains = {f: information_gain(df, f, target) for f in features}
    return max(gains, key=gains.get), gains


# ──────────────────────────────────────────────
# 2. ID3 TREE BUILDER
# ──────────────────────────────────────────────

class Node:
    """A node in the decision tree."""

    def __init__(self, feature=None, label=None):
        self.feature = feature      # splitting feature (None for leaf)
        self.label = label          # class label (None for internal node)
        self.children = {}          # {feature_value: Node}

    def is_leaf(self):
        return self.label is not None

    def __repr__(self, indent=0):
        pad = "    " * indent
        if self.is_leaf():
            return f"{pad}PREDICT: {self.label}"
        lines = [f"{pad}[{self.feature}]"]
        for val, child in sorted(self.children.items()):
            lines.append(f"{pad}  ├─ {val}:")
            lines.append(child.__repr__(indent + 2))
        return "\n".join(lines)


def id3(df, features, target, depth=0, max_depth=None):
    """
    Recursive ID3 algorithm.

    Base cases
    ----------
    1. All examples have the same label → leaf.
    2. No features left → majority-class leaf.
    3. Empty subset → caller should never reach this, but return None.
    4. max_depth reached → majority-class leaf.
    """
    labels = df[target]

    # Base case 1: pure node
    if labels.nunique() == 1:
        return Node(label=labels.iloc[0])

    # Base case 2: no features left
    if not features:
        return Node(label=labels.mode()[0])

    # Base case 4: depth limit
    if max_depth is not None and depth >= max_depth:
        return Node(label=labels.mode()[0])

    # Choose best feature
    best, gains = best_feature(df, features, target)
    node = Node(feature=best)

    remaining = [f for f in features if f != best]

    for value in df[best].unique():
        subset = df[df[best] == value]
        if subset.empty:
            # Assign majority class of current node to this branch
            node.children[value] = Node(label=labels.mode()[0])
        else:
            node.children[value] = id3(subset, remaining, target,
                                       depth + 1, max_depth)
    return node


# ──────────────────────────────────────────────
# 3. PREDICTION
# ──────────────────────────────────────────────

def predict_one(node, sample):
    """Traverse the tree for a single sample (dict or pd.Series)."""
    if node.is_leaf():
        return node.label
    val = sample[node.feature]
    if val not in node.children:
        # Unseen value at inference time — return None (could default to majority)
        return None
    return predict_one(node.children[val], sample)


def predict(node, df):
    return df.apply(lambda row: predict_one(node, row), axis=1)


# ──────────────────────────────────────────────
# 4. EVALUATION HELPERS
# ──────────────────────────────────────────────

def accuracy(y_true, y_pred):
    correct = sum(t == p for t, p in zip(y_true, y_pred))
    return correct / len(y_true)


def confusion_matrix_df(y_true, y_pred):
    classes = sorted(set(y_true) | set(y_pred))
    matrix = pd.DataFrame(0, index=classes, columns=classes)
    for t, p in zip(y_true, y_pred):
        matrix.loc[t, p] += 1
    matrix.index.name = "Actual \\ Predicted"
    return matrix


def classification_report(y_true, y_pred):
    classes = sorted(set(y_true))
    print(f"{'Class':<12} {'Precision':>10} {'Recall':>8} {'F1':>8} {'Support':>9}")
    print("-" * 50)
    for cls in classes:
        tp = sum(t == cls and p == cls for t, p in zip(y_true, y_pred))
        fp = sum(t != cls and p == cls for t, p in zip(y_true, y_pred))
        fn = sum(t == cls and p != cls for t, p in zip(y_true, y_pred))
        precision = tp / (tp + fp) if (tp + fp) else 0
        recall    = tp / (tp + fn) if (tp + fn) else 0
        f1        = (2 * precision * recall / (precision + recall)
                     if (precision + recall) else 0)
        support   = sum(t == cls for t in y_true)
        print(f"{cls:<12} {precision:>10.3f} {recall:>8.3f} {f1:>8.3f} {support:>9}")


# ──────────────────────────────────────────────
# 5. INFORMATION GAIN TABLE
# ──────────────────────────────────────────────

def print_ig_table(df, features, target):
    print(f"\n{'Feature':<15} {'Information Gain':>18}")
    print("-" * 35)
    for f in features:
        ig = information_gain(df, f, target)
        print(f"{f:<15} {ig:>18.6f}")
    print()


# ──────────────────────────────────────────────
# 6. MAIN
# ──────────────────────────────────────────────

if __name__ == "__main__":
    # ── Load data ──────────────────────────────
    df = pd.read_csv("dataset_clean.csv")
    TARGET   = "security"
    FEATURES = [c for c in df.columns if c != TARGET]

    print("=" * 60)
    print("  ID3 Decision Tree — Network Packet Security Dataset")
    print("=" * 60)
    print(f"\nDataset shape  : {df.shape}")
    print(f"Features       : {FEATURES}")
    print(f"Target         : {TARGET}")
    print(f"Class counts   :\n{df[TARGET].value_counts().to_string()}\n")

    # ── Overall entropy ───────────────────────
    H = entropy(df[TARGET])
    print(f"Dataset entropy H(S) = {H:.6f} bits\n")

    # ── Information Gain table ────────────────
    print("Information Gain for each feature (root split):")
    print_ig_table(df, FEATURES, TARGET)

    # ── Train / test split (80 / 20) ──────────
    train = df.sample(frac=0.8, random_state=42)
    test  = df.drop(train.index)
    print(f"Train size: {len(train)}  |  Test size: {len(test)}\n")

    # ── Build tree ────────────────────────────
    tree = id3(train, FEATURES, TARGET)

    print("=" * 60)
    print("  Learned Decision Tree Structure")
    print("=" * 60)
    print(tree)
    print()

    # ── Training accuracy ─────────────────────
    train_preds = predict(tree, train)
    train_acc   = accuracy(train[TARGET], train_preds)
    print(f"Training Accuracy : {train_acc:.4f} ({train_acc*100:.1f}%)\n")

    # ── Test accuracy ─────────────────────────
    test_preds = predict(tree, test)
    test_acc   = accuracy(test[TARGET], test_preds)
    print(f"Test Accuracy     : {test_acc:.4f} ({test_acc*100:.1f}%)\n")

    # ── Confusion matrix ──────────────────────
    print("Confusion Matrix (rows = Actual, cols = Predicted):")
    cm = confusion_matrix_df(test[TARGET], test_preds)
    print(cm.to_string())
    print()

    # ── Per-class report ──────────────────────
    print("Per-class Classification Report:")
    classification_report(test[TARGET], test_preds)

    # ── Predict a new sample ──────────────────
    print("\n" + "=" * 60)
    print("  Example Prediction on a New Sample")
    print("=" * 60)
    new_sample = {
        "packet_type": "sensor",
        "size": "large",
        "frequency": "high",
        "trust": "unknown",
        "anomaly": "medium"
    }
    prediction = predict_one(tree, new_sample)
    print(f"\nSample  : {new_sample}")
    print(f"Predicted security level: {prediction}")