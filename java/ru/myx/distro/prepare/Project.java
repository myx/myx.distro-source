package ru.myx.distro.prepare;

import java.io.File;
import java.io.InputStream;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import ru.myx.distro.ClasspathBuilder;
import ru.myx.distro.Utils;

public class Project {
    public static boolean checkIfProject(final Path projectRoot) {
	final String folderName = projectRoot.getFileName().toString();
	if (folderName.length() < 2 || folderName.charAt(0) == '.') {
	    // not a user-folder, hidden
	    return false;
	}
	if (!Files.isDirectory(projectRoot)) {
	    return false;
	}
	final Path infPath = projectRoot.resolve("project.inf");
	if (!Files.isRegularFile(infPath)) {
	    return false;
	}
	return true;
    }

    static Project staticLoadFromLocalIndex(final Repository repo, final String projectName, final Path projectRoot)
	    throws Exception {

	final Path infPath = projectRoot.resolve("project.inf");
	if (!Files.isRegularFile(infPath)) {
	    // doesn't have a manifest
	    return null;
	}
	final Properties info = new Properties();
	try (final InputStream in = Files.newInputStream(infPath)) {
	    info.load(in);
	}

	return new Project(projectName, info, repo);
    }

    static Project staticLoadFromLocalSource(final Repository repo, final String packageName, final Path projectPath)
	    throws Exception {
	final String folderName = projectPath.getFileName().toString();
	if (folderName.length() < 2 || folderName.charAt(0) == '.') {
	    // not a user-folder, hidden
	    return null;
	}
	final Path infPath = projectPath.resolve("project.inf");
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
	    System.err.println(Project.class.getSimpleName() + ": skipped, no 'Name' in project.inf");
	    return null;
	}
	if (!checkName.equals(packageName) && !packageName.endsWith('/' + checkName)) {
	    System.err.println(
		    Project.class.getSimpleName() + ": packageName mismatch: " + packageName + " != " + checkName);
	    return null;
	}
	final Project project = new Project(packageName, info, repo);
	project.projectSourceRoot = projectPath;
	return project;
    }

    private static void updateList(final String[] items, final List<String> list) {
	for (final String item : items) {
	    final String x = item.trim();
	    if (x.length() > 0) {
		list.add(x);
	    }
	}
    }

    private static void updateList(final String[] items, final OptionList list) {
	for (final String item : items) {
	    final String x = item.trim();
	    if (x.length() > 0) {
		list.add(new OptionListItem(x));
	    }
	}
    }

    private final List<String> lstContains = new ArrayList<>();

    private final OptionList lstProvides = new OptionList();

    private final OptionList lstRequires = new OptionList();

    public final String name;

    public final Repository repo;

    /**
     * Initialized only for projects loaded from local source
     */
    public Path projectSourceRoot = null;

    Project(final String name, final Properties info, final Repository repo) {
	this.repo = repo;
	this.name = name.trim();
	this.lstProvides.add(new OptionListItem(this.getName()));
	// a bit excessive? remove maybe? full project name is obviously well-known
	// <code>this.lstProvides.add(new OptionListItem(this.getFullName()));</code>
	if (info != null) {
	    Project.updateList(info.getProperty("Requires", "").split(" "), this.lstRequires);
	    Project.updateList(info.getProperty("Provides", "").split(" "), this.lstProvides);
	    Project.updateList(info.getProperty("Declares", "").split(" "), this.lstProvides);
	}
	if (repo != null) {
	    repo.addKnown(this);
	    if (repo.distro != null) {
		repo.distro.addKnown(this);
	    }
	}
    }

    public void buildCalculateSequence(final List<Project> sequence, final Map<String, Project> checked) {
	if (checked.putIfAbsent(this.name, this) != null) {
	    return;
	}

	final Distro distro = this.repo.distro;

	for (final OptionListItem requires : this.lstRequires) {
	    final String projectRequired = requires.getName();
	    /** full project name is unique and not checked against provides lists */
	    if (projectRequired.indexOf('/') > 0) {
		final Project project = distro.getProject(projectRequired);
		if (project != null && projectRequired.equals(project.getFullName())) {
		    project.buildCalculateSequence(sequence, checked);
		    continue;
		}
	    }
	    final Set<Project> projects = distro.getProvides().get(projectRequired);
	    if (projects == null) {
		if ("java".equals(projectRequired)) {
		    // FIXME
		    continue;
		}
		throw new IllegalArgumentException(
			"Required project is unknown, name: " + projectRequired + " for " + this.name);
	    }
	    for (final Project project : projects) {
		project.buildCalculateSequence(sequence, checked);
	    }
	}

	sequence.add(this);
    }

    public void buildPrepareCompileIndex(final ConsoleOutput console, final Path projectOutput,
	    final List<String> compileJava) throws Exception {
	this.buildPrepareDistroIndex(console, projectOutput, false);

	Utils.save(//
		console, //
		projectOutput.resolve("project-classpath.txt"), //
		this.buildPrepareCompileIndexMakeClasspath(new ClasspathBuilder())//
	);

	if (this.projectSourceRoot == null) {
	    return;
	}

	{
	    final Path dataSourcePath = this.projectSourceRoot.resolve("java");
	    if (Files.isDirectory(dataSourcePath)) {
		final Path dataOutputPath = projectOutput.resolve("java");
		Files.createDirectories(dataOutputPath);

		final List<Path> sources = new ArrayList<>();
		sources.add(dataSourcePath);

		{
		    final Path bin = this.projectSourceRoot.resolve("bin");
		    if (Files.isDirectory(bin)) {
			sources.add(bin);
		    }
		}

		Utils.sync(console, //
			sources, //
			dataOutputPath //
		);
	    }
	}
	{
	    for (final String type : new String[] { "data", "docs", "host", "jars", "image-process" }) {
		final Path dataSourcePath = this.projectSourceRoot.resolve(type);
		if (Files.isDirectory(dataSourcePath)) {
		    final Path dataOutputPath = projectOutput.resolve(type);
		    Files.createDirectories(dataOutputPath);
		    Utils.sync(console, //
			    Arrays.asList(dataSourcePath), //
			    dataOutputPath //
		    );
		}
	    }
	}
    }

    public ClasspathBuilder buildPrepareCompileIndexMakeClasspath(final ClasspathBuilder list) {
	if (this.projectSourceRoot == null) {
	    for (final String item : this.lstContains) {
		if (item.startsWith("jars/")) {
		    list.add(this.repo.name + '/' + this.name + '/' + item);
		    continue;
		}
		if (item.startsWith("java.jar")) {
		    list.add(this.repo.name + '/' + this.name + '/' + item);
		    continue;
		}
	    }
	} else {
	    for (final String item : this.lstContains) {
		if (item.startsWith("jars/")) {
		    list.add(this.repo.name + '/' + this.name + '/' + item);
		    continue;
		}
		if (item.startsWith("java.jar")) {
		    list.add(this.repo.name + '/' + this.name + "/java/");
		    continue;
		}
	    }
	}
	return list;
    }

    public void buildPrepareDistroIndex(final ConsoleOutput console, final Path packageOutput, final boolean deep)
	    throws Exception {
	Files.createDirectories(packageOutput);
	if (!Files.isDirectory(packageOutput)) {
	    throw new IllegalStateException("packageOutput is not a folder, " + packageOutput);
	}

	{
	    final Properties info = new Properties();
	    info.setProperty("Name", this.getFullName());
	    info.setProperty("Requires", this.lstRequires.toString());
	    info.setProperty("Provides", this.lstProvides.toString());

	    Utils.save(//
		    console, //
		    packageOutput.resolve("project.inf"), //
		    info, //
		    "Generated by ru.myx.distro.prepare", //
		    true//
	    );
	}

	{
	    final Properties info = new Properties();
	    info.setProperty("PROJ", this.getFullName());
	    info.setProperty("PRJS", this.getFullName());
	    this.buildPrepareDistroIndexFillProjectInfo(info);

	    Utils.save(//
		    console, //
		    packageOutput.resolve("project-index.inf"), //
		    info, //
		    "Generated by ru.myx.distro.prepare", //
		    true//
	    );
	}

	{

	    Utils.save(//
		    console, //
		    packageOutput.resolve("project-build-sequence.txt"), //
		    this.getBuildSequence().stream().map(Project::projectFullName)//
	    );

	}
    }

    void buildPrepareDistroIndexFillProjectInfo(final Properties info) throws Exception {
	info.setProperty("PRJ-REQ-" + this.getFullName(), //
		this.lstRequires.toString());
	info.setProperty("PRJ-PRV-" + this.getFullName(), //
		this.lstProvides.toString());
	info.setProperty("PRJ-SEQ-" + this.getFullName(), //
		this.getBuildSequence().stream()//
			.map(Project::projectFullName)//
			.reduce("", (t, u) -> u + " " + t).trim()//
	);
	info.setProperty("PRJ-GET-" + this.getFullName(), //
		this.lstContains.stream()//
			.reduce("", (t, u) -> u + ' ' + t).trim()//
	);
    }

    public boolean buildSource(final RepositoryBuildSourceContext ctx) throws Exception {

	final ProjectBuildSourceContext projectContext = new ProjectBuildSourceContext(this, ctx);

	final Path source = projectContext.source;
	if (!Files.isDirectory(source)) {
	    throw new IllegalStateException("source is not a folder, " + source);
	}

	final Path distro = projectContext.distro;
	Files.createDirectories(distro);
	if (!Files.isDirectory(distro)) {
	    throw new IllegalStateException("distro is not a folder, " + distro);
	}

	{
	    Files.copy(//
		    source.resolve("project.inf"), //
		    distro.resolve("project.inf"), //
		    StandardCopyOption.REPLACE_EXISTING);
	}

	final Path javaSourcePath = projectContext.source.resolve("java");
	if (Files.isDirectory(javaSourcePath)) {

	    final Path cached = projectContext.cached;
	    Files.createDirectories(cached);
	    if (!Files.isDirectory(cached)) {
		throw new IllegalStateException("cached is not a folder, " + cached);
	    }

	    ctx.addJavaCompileList(this.name);

	    ctx.addJavaSourcePath(javaSourcePath);

	    final Path javaCompilePath = projectContext.cached.resolve("java");
	    Files.createDirectories(javaCompilePath);
	    if (!Files.isDirectory(javaCompilePath)) {
		throw new IllegalStateException("Can't create project output: " + javaCompilePath);
	    }

	    ctx.addJavaClassPath(javaCompilePath);
	}

	return true;
    }

    public boolean buildSource(final DistroBuildSourceContext ctx) throws Exception {

	final ProjectBuildSourceContext projectContext = new ProjectBuildSourceContext(this, ctx);

	final Path source = projectContext.source;
	if (!Files.isDirectory(source)) {
	    throw new IllegalStateException("source is not a folder, " + source);
	}

	final Path distro = projectContext.distro;
	Files.createDirectories(distro);
	if (!Files.isDirectory(distro)) {
	    throw new IllegalStateException("distro is not a folder, " + distro);
	}

	{
	    Files.copy(//
		    source.resolve("project.inf"), //
		    distro.resolve("project.inf"), //
		    StandardCopyOption.REPLACE_EXISTING);
	}

	final Path javaSourcePath = projectContext.source.resolve("java");
	if (Files.isDirectory(javaSourcePath)) {

	    final Path cached = projectContext.cached;
	    Files.createDirectories(cached);
	    if (!Files.isDirectory(cached)) {
		throw new IllegalStateException("cached is not a folder, " + cached);
	    }

	    ctx.addJavaCompileList(this.name);

	    ctx.addJavaSourcePath(javaSourcePath);

	    final Path javaCompilePath = projectContext.cached.resolve("java");
	    Files.createDirectories(javaCompilePath);
	    if (!Files.isDirectory(javaCompilePath)) {
		throw new IllegalStateException("Can't create project output: " + javaCompilePath);
	    }

	    ctx.addJavaClassPath(javaCompilePath);
	}

	return true;
    }

    void compileAllJavaSource(final MakeCompileJava javaCompiler) throws Exception {

	{
	    final Path source = javaCompiler.sourceRoot.resolve(this.repo.name).resolve(this.name).resolve("jars");
	    if (Files.isDirectory(source)) {
		final Path output = javaCompiler.outputRoot.resolve("cached").resolve(this.repo.name).resolve(this.name)
			.resolve("jars");
		for (final Path path : Files.newDirectoryStream(source)) {
		    final String name = path.getFileName().toString();
		    if (!name.endsWith(".zip") && !name.endsWith(".jar")) {
			continue;
		    }
		    if (!Files.isRegularFile(path)) {
			continue;
		    }
		    final Path target = output.resolve(name);
		    if (Files.isRegularFile(target) && Files.getLastModifiedTime(target).toMillis() >= Files
			    .getLastModifiedTime(path).toMillis()) {
			javaCompiler.log("JAR: newer, target: " + target);
			System.err.print(".");
			continue;
		    }
		    Files.createDirectories(target.getParent());
		    Files.copy(path, target, StandardCopyOption.REPLACE_EXISTING);
		    System.err.print("c");
		}
	    }
	}
	{
	    final Path target = javaCompiler.outputRoot.resolve("cached").resolve(this.repo.name).resolve(this.name)
		    .resolve("java");

	    final Path source;
	    if (javaCompiler.sourcesFromOutput) {
		source = target;
	    } else {
		source = javaCompiler.sourceRoot.resolve(this.repo.name).resolve(this.name).resolve("java");
	    }
	    if (Files.isDirectory(source)) {
		final List<File> fileNames = new ArrayList<>();
		this.iterateJavaFiles(fileNames, source, null, target);

		System.err.print("@");

		javaCompiler.compileBatch(//
			target, //
			Arrays.asList(source.toFile()), //
			fileNames);

		{
		    final Path distro = javaCompiler.outputRoot.resolve("distro").resolve(this.repo.name)
			    .resolve(this.name).resolve("java");

		    Utils.sync(javaCompiler.console, //
			    source == target ? Arrays.asList(target) : Arrays.asList(target, source), //
			    distro//
		    );
		}
	    }
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
	final Project other = (Project) obj;
	if (this.name == null) {
	    if (other.name != null) {
		return false;
	    }
	} else if (!this.name.equals(other.name)) {
	    return false;
	}
	if (this.repo == null) {
	    if (other.repo != null) {
		return false;
	    }
	} else if (!this.repo.equals(other.repo)) {
	    return false;
	}
	return true;
    }

    public final String getName() {
	return this.name;
    }

    public final String getFullName() {
	return this.repo.name + '/' + this.name;
    }

    public OptionList getProvides() {
	return this.lstProvides;
    }

    public OptionList getRequires() {
	return this.lstRequires;
    }

    public List<Project> getBuildSequence() {
	final Map<String, Project> checked = new HashMap<>();
	final List<Project> sequence = new ArrayList<>();
	this.buildCalculateSequence(sequence, checked);
	return sequence;
    }

    @Override
    public int hashCode() {
	final int prime = 31;
	int result = 1;
	result = prime * result + (this.name == null ? 0 : this.name.hashCode());
	result = prime * result + (this.repo == null ? 0 : this.repo.hashCode());
	return result;
    }

    private void iterateJavaFiles(final List<File> files, final Path sourceRoot, final Path relativePath,
	    final Path target) throws Exception {
	final Path focus;
	if (relativePath == null) {
	    focus = sourceRoot;
	} else {
	    focus = sourceRoot.resolve(relativePath);
	}
	try (DirectoryStream<Path> directoryStream = Files.newDirectoryStream(focus)) {
	    System.err.print("*");
	    for (final Path path : directoryStream) {
		final File file = path.toFile();
		final String name = file.getName();
		if (name.startsWith(".") || name.equals("CVS")) {
		    continue;
		}
		if (file.isDirectory()) {
		    final Path newRelative;
		    if (relativePath == null) {
			newRelative = path.getFileName();
		    } else {
			newRelative = relativePath.resolve(name);
		    }
		    this.iterateJavaFiles(files, sourceRoot, newRelative, target);
		    continue;
		}
		if (!name.endsWith(".java")) {
		    continue;
		}
		if (target != null) {
		    final Path checkClass = target.resolve(relativePath)
			    .resolve(name.substring(0, name.length() - 5) + ".class");
		    if (Files.isRegularFile(checkClass)) {
			if (Files.getLastModifiedTime(checkClass).toMillis() >= file.lastModified()) {
			    // same or newer output exists
			    continue;
			}
		    }
		}
		files.add(file);
	    }
	}
    }

    public void loadFromLocalIndex(final Repository repository, final Path projectRoot) throws Exception {
	final Path infoFile = projectRoot.resolve("project-index.inf");
	if (!Files.isRegularFile(infoFile)) {
	    throw new IllegalStateException("index not found, project: " + this.name + ", path=" + infoFile);
	}
	final Properties info = new Properties();
	info.load(Files.newBufferedReader(infoFile));

	final String name = info.getProperty("PROJ", "");
	if (!this.name.equals(name)) {
	    throw new IllegalStateException(
		    "name from index does not match, project: " + this.name + ", path=" + infoFile);
	}
	this.loadFromLocalIndex(repository, info);
    }

    public void loadFromLocalIndex(final Repository repository, final Properties info) {
	Project.updateList(info.getProperty("PRJ-PRV-" + this.name, "").split(" "), this.lstProvides);
	Project.updateList(info.getProperty("PRJ-REQ-" + this.name, "").split(" "), this.lstRequires);
	Project.updateList(info.getProperty("PRJ-GET-" + this.name, "").split(" "), this.lstContains);

	for (final OptionListItem provides : this.lstProvides) {
	    this.repo.addProvides(this, provides);
	    this.repo.distro.addProvides(this, provides);
	}
    }

    public void loadFromLocalSource(final ConsoleOutput console, final Repository repository, final Path projectRoot)
	    throws Exception {

	for (final OptionListItem provides : this.lstProvides) {
	    this.repo.addProvides(this, provides);
	    this.repo.distro.addProvides(this, provides);
	}

	{
	    final Path source = projectRoot.resolve("jars");
	    if (Files.isDirectory(source)) {
		for (final Path path : Files.newDirectoryStream(source)) {
		    final String name = path.getFileName().toString();
		    if (!name.endsWith(".zip") && !name.endsWith(".jar")) {
			continue;
		    }
		    if (!Files.isRegularFile(path)) {
			continue;
		    }
		    this.lstProvides.add(new OptionListItem("classpath.jars", "jars/" + name));
		    this.lstContains.add("jars/" + name);
		    console.outProgress('l');
		}
	    }
	}
	{
	    final Path source = projectRoot.resolve("data");
	    if (Files.isDirectory(source)) {
		this.lstProvides.add(new OptionListItem("project-data", "data.tbz"));
		this.lstContains.add("data.tbz");
		console.outProgress('l');
	    }
	}
	{
	    final Path source = projectRoot.resolve("docs");
	    if (Files.isDirectory(source)) {
		this.lstProvides.add(new OptionListItem("project-docs", "docs.tbz"));
		this.lstContains.add("docs.tbz");
		console.outProgress('l');
	    }
	}
	{
	    final Path source = projectRoot.resolve("java");
	    if (Files.isDirectory(source)) {
		this.lstProvides.add(new OptionListItem("classpath.jars", "java.jar"));
		this.lstContains.add("java.jar");
		console.outProgress('l');
	    }
	}
    }

    @Override
    public String toString() {
	return this.repo.name + "/" + this.name;
    }

    public static String projectName(final Project project) {
	return project.getName();
    }

    public static String projectFullName(final Project project) {
	return project.repo.name + '/' + project.name;
    }
}
