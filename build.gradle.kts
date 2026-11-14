plugins {
    base
}

group = "me.cxdev"
version = providers.gradleProperty("releaseVersion").get()

tasks.register<Zip>("releaseZip") {
    archiveBaseName.set(project.name)
    destinationDirectory.set(layout.buildDirectory.dir("release"))
    isPreserveFileTimestamps = false
    isReproducibleFileOrder = true

    into("environment-${project.version}") {
        from(layout.projectDirectory) {
            include(
                "LICENSE", "README.md", "RELEASE_NOTES.md",
                "certificates/README.md", "certificates/cxdev_eu_auth0_com-cert.pem",
                "certificates/cxdev_eu_auth0_com-metadata.xml",
                "certificates/local.cxdev.me.crt", "certificates/local.cxdev.me.p12",
                "configuration/README.md", "configuration/profiles/*.properties",
                "dependencies/sapartefacts/README.md", "dependencies/sapjco/README.md",
                "sql/extendlicense.sql", "tools/.gitkeep",
            )
        }
        from(layout.projectDirectory) {
            include("cxdev.sh", "install.sh", "helper/*.sh")
            filePermissions { unix("755") }
        }
    }
}
