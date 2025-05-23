import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController rowsController = TextEditingController();
  TextEditingController colsController = TextEditingController();
  List<TextEditingController> controllers = [];
  List<FocusNode> focusNodes = [];

  int? rows;
  int? columns;
  List<double>? solution;
  List<List<double>>? inverseResult;

  // to focus input to next grid when inputting values
  void initControllersAndFocusNodes() {
    int total = (rows ?? 0) * (columns ?? 0);
    controllers = List.generate(
      rows! * columns!,
      (_) => TextEditingController(),
    );
    focusNodes = List.generate(total, (_) => FocusNode());
  }

  // to get the matrix from user input
  List<List<double>> getMatrixFromControllers() {
    return List.generate(rows!, (i) {
      return List.generate(columns!, (j) {
        int index = i * columns! + j;
        return double.tryParse(controllers[index].text) ?? 0.0;
      });
    });
  }

  // onPressed method for solving linear equation
  void linearEquationOnPressed() {
    if (rows == null || columns == null) return;

    // display warning if matrix is not square matrix and could result in free variable
    if (rows != columns! - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Warning: Number of equations (rows) does not equal number of variables (columns - 1). The system may have free variables or no solution.",
          ),
        ),
      );
    }

    // get matrix from user input
    List<List<double>> matrix = getMatrixFromControllers();

    // call method to solve linear equation
    List<double>? sol = solveLinearEquation(rows!, columns!, matrix);

    // if there is no solution for matrix
    if (sol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No unique solution exists for the given matrix."),
        ),
      );
      setState(() {
        solution = null;
      });
    } else {
      setState(() {
        solution = sol;
      });
    }
  }

  // method to solve linear equation
  List<double>? solveLinearEquation(
    int rows,
    int cols,
    List<List<double>> matrix,
  ) {
    int variables = cols - 1;

    // Forward elimination
    for (int pivot = 0; pivot < rows; pivot++) {
      if (matrix[pivot][pivot] == 0) {
        bool swapped = false;
        for (int i = pivot + 1; i < rows; i++) {
          if (matrix[i][pivot] != 0) {
            List<double> temp = matrix[pivot];
            matrix[pivot] = matrix[i];
            matrix[i] = temp;
            swapped = true;
            break;
          }
        }
        if (!swapped) {
          return null;
        }
      }

      for (int i = pivot + 1; i < rows; i++) {
        double factor = matrix[i][pivot] / matrix[pivot][pivot];
        for (int j = pivot; j < cols; j++) {
          matrix[i][j] -= factor * matrix[pivot][j];
        }
      }
    }

    List<double> solution = List.filled(variables, 0);

    // Back substitution
    for (int i = rows - 1; i >= 0; i--) {
      double sum = matrix[i][variables];
      for (int j = i + 1; j < variables; j++) {
        sum -= matrix[i][j] * solution[j];
      }
      solution[i] = sum / matrix[i][i];
    }

    return solution;
  }

  // onPressed method for inversing matrix
  void onInversePressed() {
    if (rows == null || columns == null) return;

    // displays warning if matrix is not a square matrix
    if (rows != columns) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Matrix must be square to find inverse.")),
      );
      return;
    }

    // get matrix from user input
    List<List<double>> matrix = getMatrixFromControllers();

    // call the method for invering matrix
    List<List<double>>? inverse = inverseMatrix(matrix);

    // displays if matrix cannot be inversed
    if (inverse == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Matrix is not invertible.")));
      setState(() {
        inverseResult = null;
      });
    } else {
      setState(() {
        inverseResult = inverse;
      });
    }
  }

  // method to inverse matrix
  List<List<double>>? inverseMatrix(List<List<double>> matrix) {
    int n = matrix.length;

    // Check square matrix
    if (matrix.any((row) => row.length != n)) {
      return null;
    }

    // Create identity matrix
    List<List<double>> identity = List.generate(
      n,
      (i) => List.generate(n, (j) => i == j ? 1.0 : 0.0),
    );

    // Copy matrix to avoid modifying original
    List<List<double>> mat = List.generate(n, (i) => List.from(matrix[i]));

    for (int i = 0; i < n; i++) {
      // Make sure pivot is not zero
      if (mat[i][i] == 0) {
        bool swapped = false;
        for (int j = i + 1; j < n; j++) {
          if (mat[j][i] != 0) {
            // Swap rows in both matrices
            List<double> tempRow = mat[i];
            mat[i] = mat[j];
            mat[j] = tempRow;

            tempRow = identity[i];
            identity[i] = identity[j];
            identity[j] = tempRow;

            swapped = true;
            break;
          }
        }
        if (!swapped) {
          return null;
        }
      }

      // Normalize pivot row
      double pivot = mat[i][i];
      for (int j = 0; j < n; j++) {
        mat[i][j] /= pivot;
        identity[i][j] /= pivot;
      }

      // Eliminate other rows
      for (int k = 0; k < n; k++) {
        if (k != i) {
          double factor = mat[k][i];
          for (int j = 0; j < n; j++) {
            mat[k][j] -= factor * mat[i][j];
            identity[k][j] -= factor * identity[i][j];
          }
        }
      }
    }

    return identity;
  }

  @override
  void dispose() {
    for (var c in controllers) c.dispose();
    for (var f in focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (rows != null && columns != null) {
      int total = rows! * columns!;
      if (controllers.length != total || focusNodes.length != total) {
        initControllersAndFocusNodes();
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Create matrix grid
            Row(
              children: [
                Text("Rows: "),
                SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: rowsController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?\d*\.?\d*$'),
                      ),
                    ],
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 20),
                Text("Columns: "),
                SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: colsController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?\d*\.?\d*$'),
                      ),
                    ],
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 20),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  rows = int.tryParse(rowsController.text);
                  columns = int.tryParse(colsController.text);
                  if (rows != null && columns != null) {
                    initControllersAndFocusNodes();
                  }
                });
              },
              child: Text("Create Matrix"),
            ),
            SizedBox(height: 20),
            Text(
              'When solving linear equation, matrix created is augmented matrix',
            ),
            SizedBox(height: 20),

            // Grid
            if (rows != null && columns != null)
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 100.0 * columns! + (columns! - 1) * 4,
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns!,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1,
                      ),
                      itemCount: rows! * columns!,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.blue[100],
                          margin: EdgeInsets.zero,
                          child: Center(
                            child: TextField(
                              controller: controllers[index],
                              focusNode: focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^-?\d*\.?\d*$'),
                                ),
                              ],
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.all(8),
                              ),
                              style: TextStyle(fontSize: 18),
                              onSubmitted: (_) {
                                int row = index ~/ columns!;
                                int col = index % columns!;

                                int nextIndex;
                                if (col < columns! - 1) {
                                  nextIndex = index + 1;
                                } else if (row < rows! - 1) {
                                  nextIndex = index + 1;
                                } else {
                                  nextIndex = 0;
                                }

                                FocusScope.of(
                                  context,
                                ).requestFocus(focusNodes[nextIndex]);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // solve linear equation / inverse matrix
            Row(
              children: [
                ElevatedButton(
                  onPressed: linearEquationOnPressed,
                  child: Text('Solve Linear Equation'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onInversePressed,
                  child: Text('Inverse Matrix'),
                ),
              ],
            ),

            // show result for solving linear equation
            if (solution != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(solution!.length, (i) {
                    String varName = String.fromCharCode(
                      120 + i,
                    ); // 'x', 'y', 'z', ...
                    return Text(
                      "$varName = ${solution![i].toStringAsFixed(4)}",
                    );
                  }),
                ),
              ),

            // show result for inversing matrix with gridview
            if (inverseResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Inverse Matrix:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...List.generate(inverseResult!.length, (i) {
                      return Text(
                        inverseResult![i]
                            .map((val) => val.toStringAsFixed(4))
                            .join('  '),
                        style: TextStyle(fontFamily: 'monospace'),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
