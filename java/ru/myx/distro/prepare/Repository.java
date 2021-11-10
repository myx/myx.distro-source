package ru.myx.distro.prepare;

import java.io.BufferedReader;
import java.io.InputStream;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import ru.myx.distro.Utils;

public class Repository {

    public static boolean checkIfRepository(final Path repositoryRoot) throws Exception {
	final Path infPath = repositoryRoot.resolve("repository.inf");
	if (!Files.isRegularFile(infPath)) {
	    return false;
	}
	return true;
    }

    public static Repository staticLoadFromLocalIndex(final Distro distro, final Path repositoryRoot) throws Exception {
	final Path infPath = repositoryRoot.resolve("repository.inf");
	if (!Files.isRegularFile(infPath)) {
	    // doesn't have a manifest
	    throw new IllegalStateException();
	}
	final Properties info = new Properties();
	try (final InputStream in = Files.newInputStream(infPath)) {
	    info.load(in);
	}
	final String repositoryName = repositoryRoot.getFileName().toString();
	final String fetch = info.getProperty("Fetch", "").trim();
	return new Repository(repositoryName, fetch.length() == 0 ? null : fetch, distro);
    }

    public static Repository staticLoadFromLocalSource(final Distro distro, final Path repositoryRoot)
	    throws Exception {
	final String repositoryName = repositoryRoot.getFileName().toString();
	final Path infPath = repositoryRoot.resolve("repository.inf");
	if (!Files.isRegularFile(infPath)) {
	    // doesn't have a manifest
	    return null;
	}
	final Properties info = new Properties();
	try (final InputStream in = Files.newInputStream(infPath)) {
	    info.load(in);
	}
	final String checkName = info.getProperty("Name", "").trim();
	if (checkName.length() == 0) {
	    // 'Name' is mandatory
	    System.err.println(Repository.class.getSimpleName() + ": skipped, no 'Name' in repository.inf ("
		    + repositoryName + ")");
	    return null;
	}
	if (!checkName.equals(repositoryName)) {
	    // 'Name' is mandatory
	    System.err.println(Repository.class.getSimpleName()
		    + ": skipped, 'Name' not equal actual folder name in repository.inf, folder: " + repositoryName);
	    return null;
	}
	final String fetch = info.getProperty("Fetch", "").trim();
	return new Repository(repositoryName, fetch.length() == 0 ? null : fetch, distro);
    }

    private final Map<String, Project> byName = new HashMap<>();

    private final Map<String, Set<Project>> byKeywords = new LinkedHashMap<>();

    private final Map<String, Set<Project>> byDeclares = new LinkedHashMap<>();

    private final Map<String, Set<Project>> byProvides = new LinkedHashMap<>();

    public final String fetch;

    public final String name;

    public final Distro distro;

    public Repository(final String name, final String fetch, final Distro distro) {
	this.name = name;
	this.fetch = fetch;
	this.distro = distro;
	if (distro != null) {
	    distro.addKnown(this);
	}
    }

    boolean addKnown(final Project project) {
	// this.byName.put(project.getName(), project);
	this.byName.put(project.getFullName(), project);
	return true;
    }

    public void addDeclares(final Project project, final OptionListItem declares) {
	Set<Project> set = this.byDeclares.get(declares.getName());
	if (set == null) {
	    set = new LinkedHashSet<>();
	    this.byDeclares.put(declares.getName(), set);
	}
	set.add(project);
    }

    public void addKeywords(final Project project, final OptionListItem keywords) {
	Set<Project> set = this.byKeywords.get(keywords.getName());
	if (set == null) {
	    set = new LinkedHashSet<>();
	    this.byKeywords.put(keywords.getName(), set);
	}
	set.add(project);
    }

    public void addProvides(final Project project, final OptionListItem provides) {
	Set<Project> set = this.byProvides.get(provides.getName());
	if (set == null) {
	    set = new LinkedHashSet<>();
	    this.byProvides.put(provides.getName(), set);
	}
	set.add(project);
    }

    public void buildPrepareDistroIndex(final ConsoleOutput console, final Distro repositories,
	    final Path repositoryOutput) throws Exception {
	Files.createDirectories(repositoryOutput);
	if (!Files.isDirectory(repositoryOutput)) {
	    throw new IllegalStateException("repositoryOutput is not a folder, " + repositoryOutput);
	}

	{
	    final Properties info = new Properties();
	    info.setProperty("Name", this.name);
	    info.setProperty("Fetch", this.fetch);

	    Utils.save(//
		    console, repositoryOutput.resolve("repository.inf"), //
		    info, //
		    "Generated by ru.myx.distro.prepare", //
		    true//
	    );
	}

	{
	    Utils.save(//
		    console, repositoryOutput.resolve("project-names.txt"), //
		    this.byName.keySet().stream().sorted() //
	    );
	}

	{
	    final Properties info = new Properties();
	    {
		info.setProperty("REPO", this.name.trim());
		info.setProperty("REPS", this.name.trim());
		info.setProperty("REP-" + this.name.trim(), this.fetch.trim());
	    }
	    {
		final StringBuilder builder = new StringBuilder(256);
		for (final Project project : this.byName.values()) {
		    builder.append(project.repo.name).append('/').append(project.name).append(' ');
		    project.buildPrepareDistroIndexFillProjectInfo(info);
		}
		info.setProperty("PRJS", builder.toString().trim());
	    }
	    {
		final Map<String, Set<Project>> provides = this.getProvides();
		for (final String provide : provides.keySet()) {
		    final StringBuilder builder = new StringBuilder(256);
		    for (final Project project : provides.get(provide)) {
			builder.append(project.repo.name).append('/').append(project.name).append(' ');
		    }
		    // not really needed (yet?)
		    // info.setProperty("PRV-" + provide, builder.toString().trim());
		}
	    }

	    Utils.save(//
		    console, //
		    repositoryOutput.resolve("repository-index.inf"), //
		    info, //
		    "Generated by ru.myx.distro.prepare", //
		    true//
	    );
	}
	{
	    // final Collection<String> lines = new TreeSet<>();
	    final Collection<String> lines = new LinkedHashSet<>();
	    for (final Project project : this.byName.values()) {
		lines.add(project.getFullName() + ' ' + project.name);
		for (final OptionListItem item : project.getProvides()) {
		    item.fillList(project.getFullName() + ' ', lines);
		}
	    }
	    Utils.save(//
		    console, repositoryOutput.resolve("repository-provides.txt"), //
		    lines.stream() //
	    );
	}
    }

    void compileAllJavaSource(final MakeCompileJava javaCompiler) throws Exception {

	for (final Project project : this.byName.values()) {
	    project.compileAllJavaSource(javaCompiler);
	}

    }

    @Override
    public boolean equals(final Object obj) {
	if (this == obj) {
	    return true;
	}
	if (obj == null) {
	    return false;
	}
	if (this.getClass() != obj.getClass()) {
	    return false;
	}
	final Repository other = (Repository) obj;
	if (this.name == null) {
	    if (other.name != null) {
		return false;
	    }
	} else if (!this.name.equals(other.name)) {
	    return false;
	}
	return true;
    }

    public String getName() {
	return this.name;
    }

    Project getProject(final String name) {
	return this.byName.get(name);
    }

    public Iterable<Project> getProjects() {
	return this.byName.values();
    }

    public Map<String, Set<Project>> getDeclares() {
	final Map<String, Set<Project>> result = new LinkedHashMap<>();
	result.putAll(this.byDeclares);
	return result;
    }

    public Map<String, Set<Project>> getKeywords() {
	final Map<String, Set<Project>> result = new LinkedHashMap<>();
	result.putAll(this.byKeywords);
	return result;
    }

    public Map<String, Set<Project>> getProvides() {
	final Map<String, Set<Project>> result = new LinkedHashMap<>();
	result.putAll(this.byProvides);
	return result;
    }

    @Override
    public int hashCode() {
	final int prime = 31;
	int result = 1;
	result = prime * result + (this.name == null ? 0 : this.name.hashCode());
	return result;
    }

    public void loadFromLocalIndex(final Distro repos, final Path repositoryRoot) throws Exception {
	{
	    final Path infoFile = repositoryRoot.resolve("repository-index.inf");
	    if (Files.isRegularFile(infoFile)) {
		final Properties info = new Properties();
		try (BufferedReader newBufferedReader = Files.newBufferedReader(infoFile)) {
		    info.load(newBufferedReader);
		}

		final String name = info.getProperty("REPO", "");
		if (!this.name.equals(name)) {
		    throw new IllegalStateException(
			    "name from index does not match, repository: " + this.name + ", path=" + infoFile);
		}
		this.loadFromLocalIndex(repos, info);
		return;
	    }
	}
	{
	    for (final String projectName : Files.readAllLines(repositoryRoot.resolve("project-names.txt"))) {
		final Path projectRoot = repositoryRoot.resolve(projectName);
		final Project project = Project.staticLoadFromLocalIndex(this, projectName, projectRoot);
		if (project != null) {
		    project.loadFromLocalIndex(this, projectRoot);
		}
	    }
	}
    }

    public void loadFromLocalIndex(final Distro repos, final Properties info) {
	for (final String projectId : info.getProperty("PRJS", "").split("\\s+")) {
	    final String projectName = projectId.substring(projectId.indexOf('/') + 1).trim();
	    if (projectName.length() == 0) {
		continue;
	    }
	    final Properties projectInfo = new Properties();
	    projectInfo.setProperty("Name", projectName);
	    final Project project = new Project(projectName, projectInfo, this);
	    project.loadFromLocalIndex(this, info);
	}
    }

    public void loadFromLocalSource(final ConsoleOutput console, final Distro repositories, final Path repositoryRoot)
	    throws Exception {

	this.loadFromLocalSource(console, repositories, repositoryRoot, repositoryRoot);
    }

    public void loadFromLocalSource(final ConsoleOutput console, final Distro repositories, final Path repositoryRoot,
	    final Path currentRoot) throws Exception {

	try (final DirectoryStream<Path> projects = Files.newDirectoryStream(currentRoot)) {

	    for (final Path projectRoot : projects) {

		if (Project.checkIfProject(projectRoot)) {

		    final Project project = Project.staticLoadFromLocalSource(//
			    this, //
			    repositoryRoot.relativize(projectRoot).toString(), //
			    projectRoot//
		    );
		    if (project != null) {
			project.loadFromLocalSource(console, this, projectRoot);
			console.outProgress('p');
		    }

		    final Path subProjectsRoot = projectRoot.resolve("source-projects");
		    if (Files.isDirectory(subProjectsRoot)) {
			try (final DirectoryStream<Path> subProjects = Files.newDirectoryStream(subProjectsRoot)) {
			    for (final Path subProjectRoot : subProjects) {
				if (Project.checkIfProject(subProjectRoot)) {
				    final Project subProject = Project.staticLoadFromLocalSource(//
					    this, //
					    repositoryRoot.relativize(subProjectRoot).toString(), //
					    subProjectRoot//
				    );
				    if (subProject != null) {
					subProject.loadFromLocalSource(console, this, subProjectRoot);
					console.outProgress('p');
				    }

				}
			    }
			}

		    }

		    continue;

		}

		final String folderName = projectRoot.getFileName().toString();
		if (folderName.length() < 2 || folderName.charAt(0) == '.') {
		    // not a user-folder, hidden
		    continue;
		}
		if (!Files.isDirectory(projectRoot)) {
		    continue;
		}

		this.loadFromLocalSource(console, repositories, repositoryRoot, projectRoot);
	    }
	}
    }

}
