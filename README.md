---

# PGet - Package Version and Path Backup Tool

PGet is a command-line tool designed to help you manage and backup package versions and paths in your Flutter projects. It's particularly useful when working across multiple laptops with different file paths for packages.

## Features

- **Backup package details**: Store package paths and versions in a `pget.yaml` file.
- **Synchronize package paths**: Automatically replace package paths and versions in `pubspec.yaml` based on `pget.yaml`.
- **Simplify multi-laptop workflow**: Ensure consistent package management across different development environments.

## Installation

To install PGet globally, run:

```bash
dart pub global activate pget
```

## Usage

PGet provides a simple command-line interface with three main commands:

### 1. Initialize Package Get (`--init`)

This command initializes the `pget.yaml` file and adds it to `.gitignore`. It will scan your `pubspec.yaml` file for packages specified with local paths and back them up in `pget.yaml`.

```bash
flutter pub run pget --init
```

**What it does:**
- Creates a `pget.yaml` file in your project root.
- Adds `pget.yaml` to `.gitignore` to avoid accidental commits.
- Backs up local package paths from `pubspec.yaml` to `pget.yaml`.

### 2. Remove PGet Configuration (`--remove`)

This command removes the `pget.yaml` file from your project and removes its entry from `.gitignore`.

```bash
flutter pub run pget --remove
```

**What it does:**
- Deletes the `pget.yaml` file from your project root.
- Removes `pget.yaml` from `.gitignore`.

### 3. Help (`-h`, `--help`)

Displays help information about the available commands.

```bash
flutter pub run pget --help
```
## Workflow Example with `pget.yaml` on More Than One Laptop

1. **Initialize on Laptop 1**:
    - Run `flutter pub run pget --init` to create a `pget.yaml` file with the local package paths specific to Laptop 1.
    - Work on the project as usual, with the `pget.yaml` file managing your package paths.

2. **Set Up on Laptop 2**:
    - Clone the project and run `flutter pub run pget --init` to create a `pget.yaml` file for Laptop 2’s specific paths.
    - The `pget.yaml` file on Laptop 2 will contain the paths that match the environment of Laptop 2.

3. **Switching Between Laptops**:
    - When switching back to Laptop 1, run `flutter pub run pget` to apply the paths from Laptop 1’s `pget.yaml` to `pubspec.yaml`.
    - Similarly, on Laptop 2, run `flutter pub run pget` to apply Laptop 2’s specific paths.

This workflow ensures that each laptop uses its respective package paths while maintaining consistency in the project’s dependencies across different environments.

## Contributing

Contributions are welcome! If you find any issues or have suggestions, feel free to open a pull request or an issue on GitHub.

## License

This project is licensed under the MIT License.

---