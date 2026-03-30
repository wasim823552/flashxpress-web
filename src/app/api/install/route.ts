import { NextResponse } from "next/server";

interface InstallOptions {
  withRedis?: boolean;
  phpVersion?: string;
  withFail2Ban?: boolean;
  withPhpMyAdmin?: boolean;
  withAdminer?: boolean;
  withFileManager?: boolean;
}

function generateInstallCommand(options: InstallOptions): string {
  const parts: string[] = ["bash <(curl -sSL https://wp.flashxpress.cloud/install.sh)"];

  const flags: string[] = [];

  if (options.phpVersion && ["8.1", "8.2", "8.3", "8.4"].includes(options.phpVersion)) {
    flags.push(`--php=${options.phpVersion}`);
  }

  if (options.withRedis === false) {
    flags.push("--no-redis");
  }

  if (options.withFail2Ban === false) {
    flags.push("--no-fail2ban");
  }

  if (options.withPhpMyAdmin === true) {
    flags.push("--with-pma");
  }

  if (options.withAdminer === true) {
    flags.push("--with-adminer");
  }

  if (options.withFileManager === true) {
    flags.push("--with-files");
  }

  if (flags.length > 0) {
    return `${parts[0]} ${flags.join(" ")}`;
  }

  return parts[0];
}

function generateExplanation(options: InstallOptions): string[] {
  const explanations: string[] = [];

  explanations.push(
    "FlashXpress will install NGINX with FastCGI Cache, MariaDB 11.4, and WP-CLI."
  );

  const phpVer = options.phpVersion || "8.4";
  explanations.push(
    `PHP ${phpVer} will be installed as the default PHP version.`
  );

  if (options.withRedis !== false) {
    explanations.push(
      "Redis Object Cache will be installed for WordPress object caching."
    );
  }

  if (options.withFail2Ban !== false) {
    explanations.push(
      "UFW Firewall and Fail2Ban will be configured for server security."
    );
  }

  if (options.withPhpMyAdmin) {
    explanations.push("phpMyAdmin will be installed for web-based database management.");
  }

  if (options.withAdminer) {
    explanations.push("Adminer will be installed as a lightweight database management tool.");
  }

  if (options.withFileManager) {
    explanations.push("File Manager will be installed for web-based file management.");
  }

  explanations.push(
    "SSL certificates can be installed after setup using: fx ssl install <domain>"
  );
  explanations.push(
    "Create your first WordPress site with: fx site create <domain>"
  );

  return explanations;
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const options: InstallOptions = {
      withRedis: body.withRedis ?? true,
      phpVersion: body.phpVersion || "8.4",
      withFail2Ban: body.withFail2Ban ?? true,
      withPhpMyAdmin: body.withPhpMyAdmin ?? false,
      withAdminer: body.withAdminer ?? false,
      withFileManager: body.withFileManager ?? false,
    };

    const command = generateInstallCommand(options);
    const explanation = generateExplanation(options);

    return NextResponse.json({
      success: true,
      command,
      explanation,
      options,
    });
  } catch {
    return NextResponse.json(
      {
        success: false,
        error: "Invalid request. Please provide valid options.",
      },
      { status: 400 }
    );
  }
}
