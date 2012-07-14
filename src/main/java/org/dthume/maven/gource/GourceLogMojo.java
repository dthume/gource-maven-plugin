package org.dthume.maven.gource;

import static org.apache.commons.lang3.StringUtils.defaultString;
import static org.apache.commons.lang3.StringUtils.isNotEmpty;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;

import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import net.sf.saxon.TransformerFactoryImpl;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.command.changelog.ChangeLogScmResult;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.ScmProviderRepositoryWithHost;
import org.apache.maven.scm.provider.svn.repository.SvnScmProviderRepository;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.maven.scm.repository.ScmRepositoryException;
import org.apache.maven.settings.Server;
import org.apache.maven.settings.Settings;
import org.dthume.jaxp.ClasspathSource;

/**
 * Generate a log in Gource format.
 * 
 * @author dth
 * 
 * @goal log
 */
public final class GourceLogMojo extends AbstractMojo {
    /**
     * The SCM connection URL.
     *
     * @parameter
     *  expression="${connectionUrl}"
     *  default-value="${project.scm.connection}"
     */
    private String connectionUrl;

    /**
     * The SCM connection URL for developers.
     *
     * @parameter
     *  expression="${connectionUrl}"
     *  default-value="${project.scm.developerConnection}"
     */
    private String developerConnectionUrl;

    /**
     * The type of connection to use (connection or developerConnection).
     *
     * @parameter expression="${connectionType}" default-value="connection"
     */
    private String connectionType;

    /**
     * The user name (used by svn, starteam and perforce protocol).
     *
     * @parameter expression="${username}"
     */
    private String username;

    /**
     * The user password (used by svn, starteam and perforce protocol).
     *
     * @parameter expression="${password}"
     */
    private String password;

    /**
     * The private key (used by java svn).
     *
     * @parameter expression="${privateKey}"
     */
    private String privateKey;

    /**
     * The passphrase (used by java svn).
     *
     * @parameter expression="${passphrase}"
     */
    private String passphrase;

    /**
     * The url of tags base directory (used by svn protocol). It is not
     * necessary to set it if you use the standard svn layout
     * (branches/tags/trunk).
     *
     * @parameter expression="${tagBase}"
     */
    private String tagBase;
    
    /**
     * The file to write the gource log to.
     * 
     * @parameter
     *  expression="${outputFile}"
     *  default-value="${project.build.directory}/gource.log"
     */
    private File outputFile;
    
    /**
     * @required
     * @readonly
     * @parameter expression="${basedir}"
     */
    private File basedir;
    
    /**
     * @parameter expression="${settings}"
     * @required
     * @readonly
     */
    private Settings settings;
    
    /**
     * @required
     * @readonly
     * @component
     */
    private ScmManager scmManager;
    
    /**
     * @required
     * @readonly
     * @component
     */
    private ChangeLogWriter changeLogWriter;
    
    /**
     * The directory to use for temporary gource files.
     * 
     * @parameter default-value="${project.build.directory}/gource"
     */
    private File workingDir;
    
    /**
     * Temporary file to use for the raw scm changes xml, before transformation
     * to gource format.
     */
    private File changeLogFile;
    
    public void execute() throws MojoExecutionException, MojoFailureException {
        initialize();
        
        try {
            generateChangeLog();
            transformToGourceLog();
        } catch (final IOException e) {
            throw new MojoExecutionException("Exception writing changelog", e);
        } catch (final ScmException e) {
            throw new MojoExecutionException("Exception getting changelog", e);
        } catch (final TransformerException e) {
            throw new MojoExecutionException("Exception creating gourcelog", e);
        }
    }
   
    private synchronized void initialize() throws MojoExecutionException {
        if (!(workingDir.exists() || workingDir.mkdirs())) {
            final String msg =
                    "Failed to creating gource working dir: " + workingDir;
            throw new MojoExecutionException(msg);
        }
        
        changeLogFile = new File(workingDir, "changes.xml");
    }
    
    private void generateChangeLog()
            throws MojoExecutionException, ScmException, IOException {
        final ScmManager scm = getScmManager();
        final ScmRepository repo = getScmRepository();
        final ScmFileSet fileset = new ScmFileSet(basedir);
        final ChangeLogScmResult result =
                scm.changeLog(repo, fileset, null, null);
        
        checkScmResult(result);
        
        final Writer logWriter = new FileWriter(changeLogFile);
        changeLogWriter.write(result.getChangeLog(), logWriter);
    }
    
    private ScmManager getScmManager() { return scmManager; }

    private ScmRepository getScmRepository() throws ScmException {
        try {
            return getScmRepositoryInternal();
        } catch (final ScmRepositoryException e) {
            if (!e.getValidationMessages().isEmpty())
                for (final String msg : e.getValidationMessages())
                    getLog().error(msg);

            throw new ScmException("Cannot load the scm provider.", e);
        } catch (final Exception e) {
            throw new ScmException("Cannot load the scm provider.", e);
        }
    }
    
    private ScmRepository getScmRepositoryInternal() throws ScmException {
        final ScmRepository repository =
                getScmManager().makeScmRepository(getConnectionUrl());

        final ScmProviderRepository providerRepo =
                repository.getProviderRepository();

        if (isNotEmpty(username)) providerRepo.setUser(username);
        if (isNotEmpty(password)) providerRepo.setPassword(password);

        if (providerRepo instanceof ScmProviderRepositoryWithHost) {
            final ScmProviderRepositoryWithHost repo =
                    (ScmProviderRepositoryWithHost) providerRepo;

            loadAuthenticationDetailsFromSettings(repo);

            if (isNotEmpty(username)) repo.setUser(username);
            if (isNotEmpty(password)) repo.setPassword(password);
            if (isNotEmpty(privateKey)) repo.setPrivateKey(privateKey);
            if (isNotEmpty(passphrase)) repo.setPassphrase(passphrase);
        }

        if (isNotEmpty(tagBase) && repository.getProvider().equals("svn")) {
            final SvnScmProviderRepository svnRepo =
                    (SvnScmProviderRepository) providerRepo;

            svnRepo.setTagBase(tagBase);
        }
        return repository;
    }

    private String getConnectionUrl() {
        final boolean useDevConnection =
                !"connection".equalsIgnoreCase(connectionType);
        
        if (!useDevConnection && isNotEmpty(connectionUrl)) {
            return connectionUrl;
        } else if (isNotEmpty(developerConnectionUrl)) {
            return developerConnectionUrl;
        }
        
        final String msg =
                (useDevConnection ? "developerConnectionUrl" : "connectionUrl")
                + " parameter not set";
        throw new NullPointerException(msg);
    }
    
    private void loadAuthenticationDetailsFromSettings(
            final ScmProviderRepositoryWithHost repo) {
        if (null != username && null != password) return;

        final int port = repo.getPort();
        final String host =
                port > 0 ? repo.getHost() + ":" + port : repo.getHost();

        final Server server = this.settings.getServer(host);

        if (null == server) return;
            
        if (null == username)
            username = settings.getServer(host).getUsername();
        if (null == password)
            password = settings.getServer(host).getPassword();
        if (null == privateKey)
            privateKey = settings.getServer(host).getPrivateKey();
        if (null == passphrase)
            passphrase = settings.getServer(host).getPassphrase();
    }
    
    private void checkScmResult(final ScmResult result)
            throws MojoExecutionException {
        if (result.isSuccess()) return;
        
        final String msg = defaultString(result.getProviderMessage());
        final String output = defaultString(result.getCommandOutput());
        
        getLog().error("Provider message:");
        getLog().error(msg);
        getLog().error("Command output:");
        getLog().error(output);
        throw new MojoExecutionException("Command failed." + msg);
    }
    
    private void transformToGourceLog()
        throws TransformerException {
        final Source source = new StreamSource(changeLogFile);
        final Result result = new StreamResult(outputFile);
        final TransformerFactory factory = new TransformerFactoryImpl();
        final Transformer transformer =
                factory.newTransformer(getTransformerSource());
        transformer.transform(source, result);
    }
    
    private Source getTransformerSource() {
        return new ClasspathSource("color-map-file-extension.xsl", getClass());
    }
}
