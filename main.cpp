#include <iostream>
#include <string>
#include <string_view>

namespace {

constexpr int kDefaultSize = 7;
constexpr int kMinimumSize = 3;
constexpr int kMaximumSize = 40;

void printUsage(std::ostream& output) {
  output << "Usage: squaredraw [--size N]\n";
  output << "Draw a stylized square with an N-by-N interior (3-40).\n";
}

bool parseSize(std::string_view text, int& size) {
  if (text.empty()) {
    return false;
  }

  int value = 0;
  for (const char character : text) {
    if (character < '0' || character > '9') {
      return false;
    }

    const int digit = character - '0';
    if (value > (kMaximumSize - digit) / 10) {
      return false;
    }
    value = value * 10 + digit;
  }

  if (value < kMinimumSize || value > kMaximumSize) {
    return false;
  }

  size = value;
  return true;
}

void drawSquare(int size) {
  const std::string border(size, '-');
  std::cout << '+' << border << "+\n";

  for (int row = 0; row < size; ++row) {
    std::string interior(size, ' ');
    interior[row] = '#';
    if (row == size / 2) {
      interior[size / 2] = '@';
    }
    std::cout << '|' << interior << "|\n";
  }

  std::cout << '+' << border << "+\n";
}

int printUsageError() {
  std::cerr << "Error: invalid arguments.\n";
  printUsage(std::cerr);
  return 2;
}

}  // namespace

int main(int argc, char* argv[]) {
  if (argc == 1) {
    drawSquare(kDefaultSize);
    return 0;
  }

  const std::string_view firstArgument = argv[1];
  if ((firstArgument == "--help" || firstArgument == "-h") && argc == 2) {
    printUsage(std::cout);
    return 0;
  }

  if (firstArgument != "--size" || argc != 3) {
    return printUsageError();
  }

  int size = 0;
  if (!parseSize(argv[2], size)) {
    return printUsageError();
  }

  drawSquare(size);
  return 0;
}
