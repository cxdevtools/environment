# CXDEV Environment

CXDEV Environment helps developers set up and manage local SAP Commerce workspaces.

## Highlights

- The installer discovers the latest published Environment release and downloads its distribution ZIP.
- certtool is installed from its own GitHub release and refreshed on subsequent installer runs. The
  separately provisioned SAP CLI is preserved.
- Version tags publish a GitHub release with this changelog and the Environment ZIP attached.

## Installation and updates

Follow the [installation instructions](https://github.com/cxdevtools/environment#installation).
The installer requires `jq` to read release metadata.
